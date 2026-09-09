# RTSP-Camera-Scanner
Script Bash para descoberta de dispositivos RTSP em redes IPv4 utilizando Nmap e abertura automática dos streams utilizando FFplay.

# RTSP Camera Scanner

Script Bash para descoberta de dispositivos RTSP em redes IPv4 utilizando **Nmap** e abertura automática dos streams utilizando **FFplay**.

O projeto foi desenvolvido com o objetivo de simplificar a identificação de câmeras IP disponíveis em uma rede autorizada e permitir a visualização dos streams RTSP encontrados de forma automatizada.

---

## Visão geral

Em ambientes com múltiplas câmeras IP, pode ser necessário identificar rapidamente quais dispositivos estão disponibilizando um serviço RTSP.

Este projeto combina:

* **Bash** — automação e controle do fluxo.
* **Nmap** — descoberta dos hosts com determinada porta TCP aberta.
* **FFplay** — reprodução dos streams RTSP.
* **RTSP** — protocolo utilizado para transmissão de mídia em dispositivos como câmeras IP e DVRs/NVRs.

O usuário informa no início:

1. O range IPv4 que deseja testar.
2. A porta TCP alvo.

O script então executa o processo automaticamente.

```text
Range IPv4
    │
    ▼
   Nmap
    │
    ▼
Hosts com porta aberta
    │
    ▼
Identificação dos IPs
    │
    ▼
Construção das URLs RTSP
    │
    ▼
FFplay
    │
    ├── Câmera 01
    ├── Câmera 02
    ├── Câmera 03
    └── ...
```

---

# Funcionalidades

## Descoberta por range IPv4

O usuário pode informar uma rede utilizando CIDR:

```text
10.0.0.0/24
```

ou outros ranges compatíveis com o Nmap.

Exemplo:

```text
192.168.1.0/24
```

---

## Porta configurável

A porta alvo também é definida durante a execução:

```text
Digite a porta alvo (ex: 554): 554
```

Isso permite utilizar o mesmo script em diferentes ambientes.

A porta escolhida é utilizada na etapa de descoberta e posteriormente na construção da URL RTSP.

---

## Descoberta utilizando Nmap

O mecanismo de descoberta utiliza:

```bash
nmap -Pn -n -p PORTA --open
```

### `-Pn`

Desconsidera a necessidade de resposta ICMP para considerar o host durante a varredura.

Isso é particularmente útil em redes onde dispositivos podem bloquear ping.

### `-n`

Desabilita resolução DNS, tornando a varredura mais rápida e evitando consultas DNS desnecessárias.

### `-p`

Define a porta que será analisada.

Exemplo:

```bash
-p 554
```

### `--open`

Faz com que sejam considerados apenas hosts que apresentem a porta como aberta.

---

# Processamento da saída do Nmap

O script utiliza o formato grepável do Nmap:

```bash
-oG -
```

Isso permite processar os resultados diretamente pelo shell.

Os endereços IP encontrados são armazenados em um array Bash:

```bash
mapfile -t CAMERAS < <(
    sudo nmap -Pn -n -p "$PORTA" --open -oG - "$REDE" |
    awk -v porta="$PORTA" '
        $0 ~ ("Ports:.*" porta "/open/tcp") {
            print $2
        }
    '
)
```

Dessa forma, somente os hosts que possuem a porta TCP selecionada como aberta são encaminhados para a etapa seguinte.

---

# Identificação numerada

Os dispositivos encontrados são apresentados de forma organizada:

```text
==========================================
       DISPOSITIVOS ENCONTRADOS: 3
==========================================

Câmera 01 -> 10.0.0.15:554
Câmera 02 -> 10.0.0.25:554
Câmera 03 -> 10.0.0.37:554
```

A numeração também é utilizada no título das janelas do FFplay.

Exemplo:

```text
Camera 01 - 10.0.0.15:554
Camera 02 - 10.0.0.25:554
Camera 03 - 10.0.0.37:554
```

Isso facilita a identificação quando várias câmeras estão sendo exibidas simultaneamente.

---

# Construção da URL RTSP

Após a descoberta, o script constrói automaticamente a URL RTSP.

O endereço IP é inserido dinamicamente:

```bash
URL="rtsp://${IP}:${PORTA}/user=${USUARIO}_password=${SENHA}_channel=0_stream=0&onvif=0.sdp?real_streamonvif=0.sdp%3Freal_stream"
```

A estrutura do stream permanece padronizada, enquanto o endereço IP e a porta são definidos durante a execução.

---

# Execução simultânea das câmeras

Um dos pontos importantes do projeto é a utilização do `&` na execução do FFplay:

```bash
ffplay \
    -rtsp_transport tcp \
    -window_title "$TITULO" \
    "$URL" &
```

Sem o `&`, o shell aguardaria o encerramento de uma instância do FFplay antes de iniciar a próxima.

Com o processo em background:

```text
Bash
 │
 ├── FFplay → Camera 01
 │
 ├── FFplay → Camera 02
 │
 ├── FFplay → Camera 03
 │
 └── FFplay → Camera N
```

Assim, múltiplos streams podem ser visualizados simultaneamente.

---

# Transporte RTSP

O FFplay é executado utilizando TCP:

```bash
-rtsp_transport tcp
```

Isso faz com que o transporte do stream RTSP utilize TCP.

Em determinados ambientes de rede isso pode proporcionar maior previsibilidade do que depender de transporte UDP, especialmente quando existem firewalls, NAT ou regras de rede intermediárias.

---

# Requisitos

O projeto foi pensado para sistemas Linux com ambiente gráfico.

Dependências:

```bash
sudo apt update
sudo apt install nmap ffmpeg
```

O pacote `ffmpeg` fornece o executável:

```bash
ffplay
```

Verifique:

```bash
nmap --version
```

e:

```bash
ffplay -version
```

---

# Instalação

Clone o projeto:

```bash
git clone https://github.com/ElcioLS/rtsp-camera-scanner.git
```

Entre no diretório:

```bash
cd rtsp-camera-scanner
```

Dê permissão de execução:

```bash
chmod +x scan_cameras.sh
```

Execute:

```bash
./scan_cameras.sh
```

---

# Utilização

Ao iniciar o programa:

```text
==========================================
       SCANNER DE CÂMERAS RTSP
==========================================

Digite o range de IPs (ex: 10.0.0.0/24):
```

Informe a rede:

```text
10.0.0.1/24
```

Em seguida:

```text
Digite a porta alvo (ex: 554):
```

Informe:

```text
554
```

O Nmap realizará a descoberta.

Se forem encontrados três dispositivos:

```text
10.0.0.15
10.0.0.25
10.0.0.37
```

o programa iniciará automaticamente três instâncias do FFplay.

---

# Exemplo completo

```text
==========================================
       SCANNER DE CÂMERAS RTSP
==========================================

Digite o range de IPs (ex: 10.0.0.0/24): 10.0.0.1/24
Digite a porta alvo (ex: 554): 554

==========================================
 CONFIGURAÇÃO
==========================================
Range : 10.0.0.1/24
Porta : 554
==========================================

[+] Escaneando...

==========================================
       DISPOSITIVOS ENCONTRADOS: 3
==========================================

Câmera 01 -> 10.0.0.15:554
Câmera 02 -> 10.0.0.25:554
Câmera 03 -> 10.0.0.37:554

==========================================
[+] Abrindo streams...
==========================================

[+] Abrindo Camera 01 - 10.0.0.15:554
[+] Abrindo Camera 02 - 10.0.0.25:554
[+] Abrindo Camera 03 - 10.0.0.37:554
```

---

# Estrutura do projeto

Uma estrutura simples pode ser utilizada:

```text
rtsp-camera-scanner/
│
├── scan_cameras.sh
├── README.md
└── LICENSE
```

O principal componente é:

```text
scan_cameras.sh
```

---

# Arquitetura do script

O funcionamento pode ser dividido em seis etapas:

### 1. Entrada

```text
Range IPv4
Porta TCP
```

### 2. Validação

O script verifica se os parâmetros foram informados e se a porta está dentro do intervalo válido:

```text
1 - 65535
```

### 3. Descoberta

O Nmap procura hosts com a porta selecionada aberta.

### 4. Processamento

O `awk` extrai os endereços IP.

### 5. Geração

O script constrói a URL RTSP para cada host encontrado.

### 6. Reprodução

O FFplay abre cada stream em uma instância independente.

---

# Possíveis evoluções

O projeto pode evoluir para uma ferramenta mais completa de gerenciamento e descoberta de streams.

Algumas possibilidades:

## Descoberta de múltiplas portas

Permitir:

```text
554,8554,10554
```

e identificar qual porta fornece RTSP.

---

## Detecção automática de RTSP

Além de verificar se a porta está aberta, o programa poderia testar efetivamente o protocolo RTSP.

Isso reduziria falsos positivos causados por serviços que simplesmente estejam escutando na porta escolhida.

---

## Suporte a UDP

Adicionar uma opção:

```text
1 - TCP
2 - UDP
```

permitindo testar diferentes transportes.

---

## ONVIF

Uma evolução natural seria adicionar descoberta através de **ONVIF**, permitindo identificar dispositivos compatíveis independentemente de uma varredura simples de portas.

---

## Interface gráfica

O projeto também poderia evoluir para uma interface utilizando:

* GTK
* Qt
* Python
* Electron
* Flutter

com uma grade de câmeras:

```text
┌──────────────┬──────────────┐
│  CAMERA 01   │  CAMERA 02   │
│              │              │
│    STREAM    │    STREAM    │
├──────────────┼──────────────┤
│  CAMERA 03   │  CAMERA 04   │
│              │              │
│    STREAM    │    STREAM    │
└──────────────┴──────────────┘
```

---

# Segurança

Este projeto deve ser utilizado **somente em redes e dispositivos para os quais você possui autorização**.

A ferramenta realiza descoberta ativa de hosts e portas e pode gerar tráfego significativo dependendo do range selecionado.

Além disso, credenciais RTSP não devem ser armazenadas diretamente em repositórios públicos.

Por exemplo, evite publicar:

```bash
SENHA='minha_senha_real'
```

em um repositório GitHub.

Uma abordagem mais segura seria utilizar variáveis de ambiente:

```bash
export RTSP_USER="admin"
export RTSP_PASSWORD="senha"
```

e no script:

```bash
USUARIO="${RTSP_USER}"
SENHA="${RTSP_PASSWORD}"
```

Também é recomendável adicionar arquivos contendo credenciais ao `.gitignore`.

---

# Conclusão

O RTSP Camera Scanner demonstra como ferramentas Linux simples podem ser combinadas para criar uma solução prática de descoberta e visualização de dispositivos de vídeo em uma rede.

A combinação:

```text
Bash + Nmap + RTSP + FFplay
```

permite construir uma ferramenta leve, sem necessidade de frameworks complexos ou infraestrutura adicional.

Além de sua utilidade prática, o projeto também serve como exemplo de integração entre:

* automação de sistemas;
* redes de computadores;
* descoberta de serviços;
* protocolos de streaming;
* processamento de saída de ferramentas;
* gerenciamento de processos Linux;
* segurança de dispositivos IoT;
* monitoramento de infraestrutura.

O projeto pode servir como base para futuras implementações envolvendo descoberta ONVIF, análise de serviços RTSP, gerenciamento de múltiplos streams e criação de uma interface dedicada para monitoramento de câmeras IP.

---

## Licença

Defina a licença de acordo com a finalidade do projeto. Para projetos de código aberto, uma opção comum é a MIT License.

---

## Autor

**Elcio**

GitHub:

`https://github.com/ElcioLS`


