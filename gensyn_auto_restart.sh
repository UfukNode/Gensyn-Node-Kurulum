#!/bin/bash

NODE_DIR="$HOME/rl-swarm"
SCREEN_NAME="swarm"
LOG_FILE="$HOME/gensyn_auto_restart.log"
CHECK_INTERVAL=30
MAX_RESTART_ATTEMPTS=5
RESTART_DELAY=10
LAST_LOG_FILE="$HOME/.gensyn_last_log_time"
LOW_VRAM_FILE="$HOME/.gensyn_low_vram_time"
MIN_VRAM_MB=2000  # 2GB

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_gpu_vram_usage() {
    nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -1
}

check_node_status() {
    if ! screen -list | grep -q "\.${SCREEN_NAME}"; then
        log_message "Screen bulunamadı!"
        return 1
    fi
    
    vram_usage=$(get_gpu_vram_usage)
    if [ -n "$vram_usage" ]; then
        log_message "GPU VRAM kullanımı: ${vram_usage}MB"
        
        if [ "$vram_usage" -lt "$MIN_VRAM_MB" ]; then
            if [ -f "$LOW_VRAM_FILE" ]; then
                low_vram_start=$(cat "$LOW_VRAM_FILE" 2>/dev/null || echo "0")
                current_time=$(date +%s)
                low_vram_duration=$((current_time - low_vram_start))
                
                if [ $low_vram_duration -gt 180 ]; then
                    log_message "GPU VRAM 3 dakikadır 2GB altında - node durmuş!"
                    rm -f "$LOW_VRAM_FILE"
                    return 1
                fi
            else
                date +%s > "$LOW_VRAM_FILE"
                log_message "GPU VRAM düşük - takip başlatıldı"
            fi
        else
            if [ -f "$LOW_VRAM_FILE" ]; then
                rm -f "$LOW_VRAM_FILE"
                log_message "GPU VRAM normale döndü"
            fi
        fi
    fi
    
    if pgrep -f "python.*run_rl_swarm" > /dev/null || pgrep -f "python.*main" > /dev/null; then
        return 0
    else
        log_message "Python process bulunamadı!"
        return 1
    fi
}

start_node() {
    log_message "Node başlatılıyor..."
    
    rm -f "$LOW_VRAM_FILE" 2>/dev/null
    
    pkill -9 -f "python.*run_rl_swarm" 2>/dev/null
    pkill -9 -f "python.*main" 2>/dev/null
    pkill -9 -f "wandb" 2>/dev/null
    
    if screen -list | grep -q "\.${SCREEN_NAME}"; then
        log_message "Eski screen oturumu temizleniyor..."
        screen -S "$SCREEN_NAME" -X quit 2>/dev/null
        sleep 3
        screen -wipe 2>/dev/null
    fi
    
    cd "$NODE_DIR" || {
        log_message "HATA: Node dizini bulunamadı: $NODE_DIR"
        return 1
    }
    
    if [ ! -d ".venv" ]; then
        log_message "HATA: Virtual environment bulunamadı!"
        return 1
    fi
    
    date +%s > "$LAST_LOG_FILE"
    
    screen -dmS "$SCREEN_NAME" bash -c "
        cd '$NODE_DIR'
        
        source .venv/bin/activate
        
        echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] Node başlatılıyor...\" | tee -a '$LOG_FILE'
        
        while true; do
            echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] run_rl_swarm.sh çalıştırılıyor...\" | tee -a '$LOG_FILE'
            
            (
                {
                    sleep 5
                    echo 'n'
                    sleep 2
                    echo ''
                    sleep 2
                    echo 'y'
                    sleep 2
                    echo 'y'
                } | ./run_rl_swarm.sh 2>&1 | while IFS= read -r line; do
                    echo \"\$line\" | tee -a '$LOG_FILE'
                    if echo \"\$line\" | grep -qE 'Starting round:|Already finished round:|Joining round:|logging_utils|genrl.logging'; then
                        date +%s > '$LAST_LOG_FILE'
                    fi
                done
            )
            
            exit_code=\$?
            
            echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] Node sonlandı (exit code: \$exit_code)\" | tee -a '$LOG_FILE'
            
            pkill -9 -f 'python.*run_rl_swarm' 2>/dev/null
            pkill -9 -f 'python.*main' 2>/dev/null
            pkill -9 -f 'wandb' 2>/dev/null
            
            echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] $RESTART_DELAY saniye bekleniyor...\" | tee -a '$LOG_FILE'
            sleep $RESTART_DELAY
        done
    "
    
    sleep 10
    
    if check_node_status; then
        log_message "Node başarıyla başlatıldı!"
        return 0
    else
        log_message "Node başlatılamadı!"
        return 1
    fi
}

show_node_status() {
    echo "=== Node Durumu ==="
    if check_node_status; then
        echo "Node ÇALIŞIYOR"
        echo ""
        echo "Screen oturumları:"
        screen -ls | grep "$SCREEN_NAME"
        echo ""
        echo "Python process'leri:"
        pgrep -af "python.*run_rl_swarm" || pgrep -af "python.*main" || echo "Process bulunamadı"
    else
        echo "Node ÇALIŞMIYOR"
    fi
    echo ""
    echo "Son 10 log kaydı:"
    tail -n 10 "$LOG_FILE" 2>/dev/null || echo "Log dosyası bulunamadı"
}

monitor_node() {
    log_message "Gensyn Node Auto-Restart Script başlatıldı"
    log_message "Node dizini: $NODE_DIR"
    log_message "Kontrol aralığı: $CHECK_INTERVAL saniye"
    log_message "Log dosyası: $LOG_FILE"
    
    restart_count=0
    consecutive_failures=0
    last_restart_time=0
    
    while true; do
        log_message "Node durumu kontrol ediliyor..."
        
        if check_node_status; then
            if [ $consecutive_failures -gt 0 ]; then
                log_message "Node stabil çalışıyor. Hata sayacı sıfırlandı."
                consecutive_failures=0
            fi
        else
            current_time=$(date +%s)
            restart_count=$((restart_count + 1))
            consecutive_failures=$((consecutive_failures + 1))
            
            log_message "Node durmuş! Toplam restart: $restart_count (Art arda: $consecutive_failures)"
            
            if [ $consecutive_failures -le $MAX_RESTART_ATTEMPTS ]; then
                if start_node; then
                    log_message "Node yeniden başlatıldı! (Deneme: $consecutive_failures/$MAX_RESTART_ATTEMPTS)"
                    last_restart_time=$current_time
                    sleep 60
                    if check_node_status; then
                        consecutive_failures=0
                    fi
                else
                    log_message "Node başlatılamadı! (Deneme: $consecutive_failures/$MAX_RESTART_ATTEMPTS)"
                fi
            else
                log_message "KRITIK: Maksimum restart deneme sayısına ulaşıldı!"
                log_message "10 dakika bekleniyor..."
                sleep 600
                consecutive_failures=0
            fi
        fi
        
        sleep $CHECK_INTERVAL
    done
}

cleanup() {
    log_message "Auto-restart script durduruluyor..."
    exit 0
}

trap cleanup SIGTERM SIGINT

case "${1:-}" in
    "status")
        show_node_status
        exit 0
        ;;
    "start")
        if check_node_status; then
            echo "Node zaten çalışıyor!"
            exit 0
        else
            echo "Node başlatılıyor..."
            start_node
            exit $?
        fi
        ;;
    "stop")
        echo "Auto-restart durduruluyor..."
        pkill -f "bash.*gensyn_auto_restart.sh" 2>/dev/null
        exit 0
        ;;
    "logs")
        echo "Log dosyası izleniyor... (Çıkmak için CTRL+C)"
        tail -f "$LOG_FILE"
        exit 0
        ;;
    "clean")
        echo "Temizlik yapılıyor..."
        pkill -f "python.*run_rl_swarm" 2>/dev/null
        pkill -f "python.*main" 2>/dev/null
        screen -S "$SCREEN_NAME" -X quit 2>/dev/null
        echo "Temizlik tamamlandı!"
        exit 0
        ;;
    "")
        ;;
    *)
        echo "Kullanım: $0 [start|stop|status|logs|clean]"
        echo "  start  - Node'u başlat"
        echo "  stop   - Auto-restart'ı durdur"
        echo "  status - Node durumunu göster"
        echo "  logs   - Log dosyasını izle"
        echo "  clean  - Tüm process'leri temizle"
        echo "  (parametresiz) - Auto-restart monitoring başlat"
        exit 1
        ;;
esac

if [ ! -d "$NODE_DIR" ]; then
    log_message "HATA: Node dizini bulunamadı: $NODE_DIR"
    exit 1
fi

if [ ! -f "$NODE_DIR/run_rl_swarm.sh" ]; then
    log_message "HATA: run_rl_swarm.sh dosyası bulunamadı!"
    exit 1
fi

if ! check_node_status; then
    log_message "Node çalışmıyor, başlatılıyor..."
    start_node
fi

log_message "Monitoring başlatılıyor..."
monitor_node
