#!/bin/bash

clear

echo "=========================================="
echo "       SCANNER DE CÂMERAS RTSP"
echo "=========================================="
echo

read -rp "Digite o range de IPs (ex: 10.0.0.0/24): " REDE

if [[ -z "$REDE" ]]; then
    echo "[ERRO] Range não informado."
    exit 1
fi

read -rp "Digite a porta alvo (ex: 554): " PORTA

if [[ -z "$PORTA" ]]; then
    echo "[ERRO] Porta não informada."
    exit 1
fi

# Validação da porta
if ! [[ "$PORTA" =~ ^[0-9]+$ ]] || (( PORTA < 1 || PORTA > 65535 )); then
    echo "[ERRO] Porta inválida."
    exit 1
fi

echo

read -rp "Digite o usuário RTSP: " USUARIO

if [[ -z "$USUARIO" ]]; then
    echo "[ERRO] Usuário não informado."
    exit 1
fi

read -rsp "Digite a senha RTSP: " SENHA
echo

if [[ -z "$SENHA" ]]; then
    echo "[ERRO] Senha não informada."
    exit 1
fi

# Verifica dependências
for CMD in nmap ffplay; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "[ERRO] '$CMD' não está instalado."
        exit 1
    fi
done

echo
echo "=========================================="
echo " CONFIGURAÇÃO"
echo "=========================================="
echo "Range : $REDE"
echo "Porta : $PORTA"
echo "Usuário: $USUARIO"
echo "Senha : ********"
echo "=========================================="
echo

echo "[+] Escaneando..."
echo

mapfile -t CAMERAS < <(
    sudo nmap -T 5 -Pn -n -p "$PORTA" --open -oG - "$REDE" 2>/dev/null |
    awk -v porta="$PORTA" '
        $0 ~ ("Ports:.*" porta "/open/tcp") {
            print $2
        }
    '
)

TOTAL=${#CAMERAS[@]}

if (( TOTAL == 0 )); then
    echo
    echo "[!] Nenhum dispositivo encontrado na porta $PORTA."
    exit 0
fi

echo
echo "=========================================="
echo "       DISPOSITIVOS ENCONTRADOS: $TOTAL"
echo "=========================================="

for i in "${!CAMERAS[@]}"; do
    NUM=$((i + 1))
    printf "Câmera %02d -> %s:%s\n" \
        "$NUM" "${CAMERAS[$i]}" "$PORTA"
done

echo
echo "=========================================="
echo "[+] Abrindo streams..."
echo "=========================================="
echo

NUM=1

for IP in "${CAMERAS[@]}"; do

    # Monta a URL RTSP usando os dados informados
    URL="rtsp://${IP}:${PORTA}/user=${USUARIO}_password=${SENHA}_channel=0_stream=0&onvif=0.sdp?real_streamonvif=0.sdp%3Freal_stream"

    TITULO=$(printf "Camera %02d - %s:%s" "$NUM" "$IP" "$PORTA")

    echo "[+] Abrindo $TITULO"

    ffplay \
        -loglevel warning \
        -rtsp_transport tcp \
        -window_title "$TITULO" \
        "$URL" &

    NUM=$((NUM + 1))

    sleep 1
done

echo
echo "=========================================="
echo " $TOTAL instância(s) do ffplay iniciada(s)"
echo "=========================================="
echo

wait
