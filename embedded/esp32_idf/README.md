# ESP32 BLE Signal Controller

> **Projeto de Doutorado — ITA (Instituto Tecnológico de Aeronáutica)**
> Firmware embarcado para ESP32 utilizando ESP-IDF v5.5.1, com controle de sinais digitais em tempo real, leitura analógica e comunicação Bluetooth Low Energy (BLE).

---

## Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Estrutura de Diretórios](#estrutura-de-diretórios)
4. [Módulos do Projeto](#módulos-do-projeto)
   - [main.cpp — Ponto de Entrada](#maincpp--ponto-de-entrada)
   - [ble_controller — Controlador BLE](#ble_controller--controlador-ble)
   - [signal_controller — Gerador de Sinais](#signal_controller--gerador-de-sinais)
   - [helper_analog — Leitura Analógica (ADC)](#helper_analog--leitura-analógica-adc)
   - [helper_matrix — Operações Matriciais](#helper_matrix--operações-matriciais)
   - [helper_datasetter — Datasets Pré-calculados](#helper_datasetter--datasets-pré-calculados)
   - [helper_note — Sistema de Mensagens](#helper_note--sistema-de-mensagens)
   - [helper_led — Controle de LED](#helper_led--controle-de-led)
   - [helper_common — Utilitários e Estado Global](#helper_common--utilitários-e-estado-global)
5. [Mapeamento de Pinos (GPIO)](#mapeamento-de-pinos-gpio)
6. [Protocolo de Comunicação BLE](#protocolo-de-comunicação-ble)
7. [Fluxo de Dados e Controle](#fluxo-de-dados-e-controle)
8. [Estruturas de Dados Principais](#estruturas-de-dados-principais)
9. [Tarefas FreeRTOS](#tarefas-freertos)
10. [Como Compilar e Gravar](#como-compilar-e-gravar)
11. [Configuração](#configuração)
12. [TODO / Roadmap](#todo--roadmap)

---

## Visão Geral

Este firmware implementa um **controlador de sinais digitais em tempo real** para o ESP32, voltado para aplicações de pesquisa em controle. As principais capacidades são:

- **Geração de sinais digitais** de alta precisão (nível de microsegundos) em 6 pinos GPIO, com suporte a *dead time* configurável
- **Comunicação BLE (GATT Server)** para receber comandos e enviar telemetria a um cliente (ex: app móvel ou desktop)
- **Leitura analógica** de até 6 canais ADC com calibração por interpolação linear
- **Operações matriciais** embarcadas (multiplicação matriz×vetor) para ação de controle
- **Double buffering** de datasets de sinais para atualização em tempo real sem interromper a geração
- **Datasets pré-calculados** parametrizados por *alpha* (razão cíclica), com matrizes de ganho K associadas

O projeto é compilado com **ESP-IDF v5.5.1** e configurado para **BLE 4.2** (Bluedroid stack).

---

## Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTE BLE                          │
│               (App Mobile / Desktop / Browser)              │
└──────────────────────────┬──────────────────────────────────┘
                           │ BLE GATT (Write/Notify)
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                       ESP32 (Core 0)                         │
│  ┌───────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ BLE Controller│  │ Analog Task  │  │ Analog Action Task│  │
│  │  (GATT Server)│  │ (monitoração)│  │ (sob demanda)     │  │
│  │               │  │              │  │                   │  │
│  │  ble_router() │  │ 500ms loop   │  │ semaphore-driven  │  │
│  └──────┬────────┘  └──────┬───────┘  └───────┬───────────┘  │
│         │                 │                   │              │
│         ▼                 ▼                   ▼              │
│  ┌───────────────────────────────────────────────────┐       │
│  │               Estado Global                       │       │
│  │  g_system_state, g_dataset_a/b, g_active_set      │       │
│  │  g_cycle_nrun, g_cycle_us_delay_up/down           │       │
│  └──────────────────────┬────────────────────────────┘       │
└─────────────────────────┼────────────────────────────────────┘
                          │
┌─────────────────────────┼────────────────────────────────────┐
│                       ESP32 (Core 1)                         │
│  ┌──────────────────────▼────────────────────────────┐       │
│  │            Signal Loop Task                       │       │
│  │  - Execução de padrão de sinais digitais          │       │
│  │  - Dead time entre transições                     │       │
│  │  - Double buffer swap (SET_A ↔ SET_B)             │       │
│  │  - GPIO direto via registradores (out_w1ts/w1tc)  │       │
│  │  - Interrupções DESABILITADAS durante execução    │       │
│  └───────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────┘
```

### Distribuição entre Cores

| Core | Função |
|------|--------|
| **Core 0 (PRO_CPU)** | BLE stack, BLE Router, Analog Reading Task, Analog Action Task, Blink Task |
| **Core 1 (APP_CPU)** | Signal Loop Task (prioridade 10, interrupções desabilitadas) |

---

## Estrutura de Diretórios

```
esp32_idf/
├── CMakeLists.txt              # Build system raiz (projeto "ble_test")
├── README.md                   # Esta documentação
├── TODO                        # Lista de pendências do projeto
├── sdkconfig.defaults          # BT_ENABLED, BLE 4.2
├── sdkconfig                   # Configurações completas (menuconfig)
├── dependencies.lock           # Lock do gerenciador de componentes
├── bla.excalidraw              # Diagrama visual (Excalidraw)
├── doc/
│   ├── hw_esp32_pins.png       # Diagrama de pinagem do hardware
│   └── hw_esp32_pins_full.png  # Diagrama completo de pinagem
├── main/
│   ├── CMakeLists.txt          # Registro de componente IDF
│   ├── Kconfig.projbuild       # Opções do menuconfig
│   ├── idf_component.yml       # Dependências IDF (>=4.1.0)
│   ├── main.cpp                # Ponto de entrada (app_main)
│   ├── include/
│   │   ├── ble_controller.h    # API do controlador BLE
│   │   ├── signal_controller.h # API do gerador de sinais
│   │   ├── helper_analog.h     # API de leitura analógica
│   │   ├── helper_matrix.h     # API de operações matriciais
│   │   ├── helper_datasetter.h # API de datasets pré-calculados
│   │   ├── helper_note.h       # API do sistema de mensagens
│   │   ├── helper_led.h        # API do LED
│   │   └── helper_common.h     # Tipos, enums, estado global, utilitários
│   └── src/
│       ├── ble_controller.cpp  # Implementação BLE (~615 linhas)
│       ├── signal_controller.cpp # Geração de sinais (~337 linhas)
│       ├── helper_analog.cpp   # ADC + calibração (~108 linhas)
│       ├── helper_matrix.cpp   # Multiplicação matricial (~132 linhas)
│       ├── helper_datasetter.cpp # LUT de datasets (~4144 linhas, auto-gerado)
│       ├── helper_note.cpp     # Buffer de mensagens (~123 linhas)
│       ├── helper_led.cpp      # Controle GPIO do LED (~37 linhas)
│       └── helper_common.cpp   # Utilitários + estado global (~119 linhas)
├── sandbox/
│   └── condition_signal/       # Experimentos / sandbox
└── build/                      # Artefatos de compilação
```

---

## Módulos do Projeto

### `main.cpp` — Ponto de Entrada

**Arquivo:** `main/main.cpp` (222 linhas)

Responsabilidades:
- Verifica e reporta a **frequência da CPU** (ideal: 240 MHz)
- Invoca `app_init()` que inicializa todos os subsistemas na ordem:
  1. `led_init()` — GPIO do LED
  2. `analog_init()` — ADC1 (6 canais)
  3. `signal_controller_init()` — GPIOs de sinal + padrão padrão
  4. `nvs_flash_init()` — Non-Volatile Storage
  5. `ble_controller_init()` — Stack Bluetooth completa
  6. Criação do semáforo `sem_analog_read_trigger`
- Cria **3 tarefas FreeRTOS** no Core 0:
  - `analog_reading_task` — monitoração analógica periódica (8KB stack)
  - `analog_action_task` — leitura analógica sob demanda via semáforo (4KB stack)
  - `blink_task` — (criada sob demanda via comando BLE)
- Executa `matrix_test()` — verificação das operações matriciais
- Executa `blink(4)` — feedback visual de boot completo

### `ble_controller` — Controlador BLE

**Arquivos:** `include/ble_controller.h` + `src/ble_controller.cpp` (615 linhas)

Implementa um **GATT Server** com:
- **Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Characteristic UUID:** `beb5483e-36e1-4688-b7f5-ea07361b26a8`
- Propriedades: **Read + Write + Notify**
- MTU local: **500 bytes**

**Funcionalidades principais:**
- `ble_controller_init()` — inicializa todo o stack BLE (Controller → Bluedroid → GAP → GATTS)
- `ble_send_message()` — envia notificação BLE ao cliente conectado
- `ble_router()` — **roteador de comandos**, interpreta mensagens recebidas via Write e despacha para o handler correto
- `ble_is_connected()` — verifica se há cliente conectado

#### Comandos BLE Disponíveis

| Comando | Descrição |
|---------|-----------|
| `on` | Liga o LED (e para o blink) |
| `off` | Desliga o LED (e para o blink) |
| `blink` | Inicia blink com delays padrão (200ms / 500ms) |
| `blink:<d1>` | Blink com delay customizado |
| `blink:<d1>,<d2>` | Blink com dois delays customizados |
| `read` | Lê e retorna os 3 canais analógicos (AN3, AN5, AN6) |
| `status` | Retorna estado completo do sistema |
| `start` | Inicia geração contínua de sinais (Core 1) |
| `stop` | Para a geração de sinais |
| `SIGNAL:<data>` | Atualiza padrão de sinal via double buffer |
| `SET_ALPHA:<value>` | Carrega dataset pré-calculado pelo valor de alpha |
| `active_dataset` | Imprime o dataset ativo |
| `status_matrix_a` | Mostra a matriz K do dataset A |
| `status_matrix_b` | Mostra a matriz K do dataset B |
| `log_duration` | Mostra tempos de execução internos |
| `ble_read_on` | Habilita leitura analógica via BLE |
| `ble_read_off` | Desabilita leitura analógica via BLE |
| `port:<n>,<v>` | Define valor (0/1) de uma porta GPIO específica (1-6) |
| `cycles:<n>` | Define `g_cycle_nrun` (ciclos entre leituras analógicas) |
| `us_delay:<n>` | Define dead time (up e down, em ciclos de clock) |
| `us_delay_up:<n>` | Define dead time de subida |
| `us_delay_down:<n>` | Define dead time de descida |
| `an_monitor_ms:<n>` | Define período de monitoração analógica (ms) |

### `signal_controller` — Gerador de Sinais

**Arquivos:** `include/signal_controller.h` + `src/signal_controller.cpp` (337 linhas)

Implementa o loop de geração de sinais digitais de **alta precisão** com as seguintes características:

- **6 saídas digitais** organizadas em 3 pares complementares (d4/d4', d5/d5', d6/d6')
- **Dead time** configurável entre transições (rising/falling com delays diferentes)
- **Double buffering** — dois `DataSet` (A e B), permitindo atualização de padrão sem parar o sinal
- **Execução no Core 1** com prioridade 10 e **interrupções desabilitadas**
- Acesso direto a registradores GPIO (`GPIO.out_w1ts`, `GPIO.out_w1tc`) para velocidade máxima
- Delays via `esp_rom_delay_us()` e `helper_delay_cycles()` (contagem de ciclos de CPU)

**Estrutura `DataSet`:**
```c
struct DataSet {
    uint32_t time_durations[MAX_SIGNAL_SIZE];   // Duração de cada segmento (µs)
    uint32_t modes_d4[MAX_SIGNAL_SIZE];         // Estado do par d4 (0 ou 1)
    uint32_t modes_d5[MAX_SIGNAL_SIZE];         // Estado do par d5 (0 ou 1)
    uint32_t modes_d6[MAX_SIGNAL_SIZE];         // Estado do par d6 (0 ou 1)
    uint32_t size;                               // Número de segmentos
    int32_t  time_us_diff[MAX_SIGNAL_SIZE];     // (reservado)
    float    target[3];                          // Vetor alvo para controle
    MatrixData gain_k;                           // Matriz de ganho K
};
```

**Fluxo de atualização (Double Buffer):**
1. Cliente BLE envia novo sinal → `signal_update_from_string()`
2. Novo sinal é escrito no dataset **inativo** (ex: SET_B se SET_A está ativo)
3. Flag `g_ds_update_pending = true` é setada
4. No início do próximo ciclo, `signal_loop_task` detecta o flag e faz o swap
5. O dataset anterior fica disponível para próxima escrita

### `helper_analog` — Leitura Analógica (ADC)

**Arquivos:** `include/helper_analog.h` + `src/helper_analog.cpp` (108 linhas)

- Inicializa **ADC1** com 6 canais (12-bit, atenuação 12dB, ref 3.3V)
- Calibração por **interpolação linear** (lookup table de 33 pontos)
- Retorna tensão em Volts após calibração

**Mapeamento de Portas Analógicas:**

| Porta | Canal ADC | GPIO |
|-------|-----------|------|
| AN1 | ADC1_CHANNEL_3 | GPIO 39 |
| AN2 | ADC1_CHANNEL_5 | GPIO 33 |
| AN3 | ADC1_CHANNEL_4 | GPIO 32 |
| AN4 | ADC1_CHANNEL_7 | GPIO 35 |
| AN5 | ADC1_CHANNEL_6 | GPIO 34 |
| AN6 | ADC1_CHANNEL_0 | GPIO 36 |

### `helper_matrix` — Operações Matriciais

**Arquivos:** `include/helper_matrix.h` + `src/helper_matrix.cpp` (132 linhas)

- Estrutura `MatrixData` para matrizes de tamanho até `MAX_MATRIX_ELEMENTS` (100)
- `matrix_multiply_vector3()` — multiplicação matriz (NxM) × vetor (3×1)
- `matrix_isvalid()` — validação de dimensões
- `matrix_print()` — impressão via ESP_LOG
- `matrix_test()` — suite de testes automáticos (identidade, 2×3, 1×3, 4×3, fracionários)

### `helper_datasetter` — Datasets Pré-calculados

**Arquivos:** `include/helper_datasetter.h` + `src/helper_datasetter.cpp` (4144 linhas)

- Arquivo **auto-gerado** (provavelmente via MATLAB/script)
- Contém `helper_set_dataset_from_alpha()` — uma grande cadeia de `if/else if` que configura o `DataSet` completo (tempos, modos, target, matriz de ganho K) baseado no valor de **alpha** (razão cíclica)
- Valores de alpha: de **0.10 a ~0.90** com incremento de 0.01
- Cada alpha define:
  - 6 segmentos de tempo com respectivos modos para d4, d5, d6
  - Vetor `target[3]` (setpoint de controle)
  - Matriz de ganho `gain_k` (5×3 = 15 elementos)

### `helper_note` — Sistema de Mensagens

**Arquivos:** `include/helper_note.h` + `src/helper_note.cpp` (123 linhas)

Sistema de **buffer de texto** usado para montar mensagens estruturadas antes de enviá-las via BLE ou log serial.

- `NoteData` — struct com buffer dinâmico, índice e flag de overflow
- `note_clear()` — limpa o buffer
- `note_add_text()` — adiciona texto formatado (estilo printf) ao buffer
- `note_add_array_u32/i32()` — serializa arrays numéricos
- `note_add_matrix()` — serializa `MatrixData`
- `note_ble_send()` — envia o conteúdo do buffer via `ble_send_message()`
- `note_logi/logw/loge()` — imprime via ESP_LOG

**Constantes de tamanho:**
- `NOTE_BUFFER_SIZE` = 2048 (buffer padrão)
- `NOTE_BLE_BUFFER_SIZE` = 497 (limite BLE — MTU)
- `NOTE_TEMP_BUFFER_SIZE` = 256 (buffer temporário para formatação)

### `helper_led` — Controle de LED

**Arquivos:** `include/helper_led.h` + `src/helper_led.cpp` (37 linhas)

- LED no **GPIO 2** (LED onboard do ESP32 DevKit)
- `led_init()` — configura GPIO como output
- `led_on()` / `led_off()` — liga/desliga
- `get_led_state()` — retorna estado atual

### `helper_common` — Utilitários e Estado Global

**Arquivos:** `include/helper_common.h` + `src/helper_common.cpp` (119 linhas)

**Estado global:**
- `g_system_state` — struct `SystemState` contendo `SignalState` e `BLEAnalogReadState`
- `g_analog_monitor_period_ms` — período de monitoração analógica (padrão: 500ms)
- `g_log_duration` — timestamps para profiling de operações internas
- `sem_analog_read_trigger` — semáforo para trigger de leitura analógica

**Enums:**
| Enum | Valores | Uso |
|------|---------|-----|
| `BLEMode` | `SILENT`, `VERBOSE` | Controla logging de envio BLE |
| `Status` | `ON`, `OFF` | Liga/desliga funcionalidades |
| `SignalSet` | `SET_A`, `SET_B` | Identifica o dataset ativo |
| `BLEAnalogReadState` | `IDLE`, `READING`, `DISABLED` | Estado da leitura analógica |
| `SignalState` | `IDLE`, `RUNNING` | Estado da geração de sinais |

**Utilitários:**
- `blink(N)` — blink N vezes (100ms on/off)
- `num2bin()` — converte número para representação binária (6 bits)
- `parse_signal()` — faz parsing de string `"t1,t2,...;m1,m2,..."` para vetores de tempo e modo
- `get_label()` — converte enums para string
- `helper_delay_cycles()` — delay inline por contagem de ciclos de CPU

---

## Mapeamento de Pinos (GPIO)

### Saídas Digitais (Sinal)

| Nome | GPIO | Função |
|------|------|--------|
| `PIN_OUT_6` | GPIO 23 | Saída digital 6 (bit 2 — direto) |
| `PIN_OUT_6_` | GPIO 22 | Saída digital 6' (complementar) |
| `PIN_OUT_5` | GPIO 21 | Saída digital 5 (bit 1 — direto) |
| `PIN_OUT_5_` | GPIO 19 | Saída digital 5' (complementar) |
| `PIN_OUT_4` | GPIO 18 | Saída digital 4 (bit 0 — direto) |
| `PIN_OUT_4_` | GPIO 17 | Saída digital 4' (complementar) |
| `PIN_OUT_SIG` | GPIO 16 | Sinal auxiliar |

### Entradas Analógicas (ADC1)

| Porta | GPIO | Canal ADC |
|-------|------|-----------|
| AN1 | 39 (SVN) | ADC1_CH3 |
| AN2 | 33 | ADC1_CH5 |
| AN3 | 32 | ADC1_CH4 |
| AN4 | 35 | ADC1_CH7 |
| AN5 | 34 | ADC1_CH6 |
| AN6 | 36 (SVP) | ADC1_CH0 |

### Outros

| Nome | GPIO | Função |
|------|------|--------|
| LED | GPIO 2 | LED onboard |

---

## Protocolo de Comunicação BLE

### Configuração GATT

| Parâmetro | Valor |
|-----------|-------|
| **Device Name** | Configurado via menuconfig |
| **Service UUID** | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| **Characteristic UUID** | `beb5483e-36e1-4688-b7f5-ea07361b26a8` |
| **Propriedades** | Read, Write, Notify |
| **MTU** | 500 bytes |
| **Advertising** | General Discoverable, BLE only |
| **Intervalo Adv** | 0x20 – 0x40 (20–40ms) |

### Formato de Mensagens

**Entrada (Write → ESP32):**
- Strings UTF-8 terminadas naturalmente pelo tamanho do write
- Case-insensitive para a maioria dos comandos
- Exceções case-sensitive: `SIGNAL:` e `SET_ALPHA:` (prefixos)

**Saída (Notify ← ESP32):**
- Mensagens de status prefixadas com `\nSTATUS\n`
- Dados analógicos no formato: `an3:X.XXXX an5:X.XXXX an6:X.XXXX`
- Arrays no formato: `nome: [v1,v2,...,vN];`

### Formato do Sinal (`SIGNAL:`)

```
SIGNAL:t1,t2,t3,...,tN;m1,m2,m3,...,mN
```

Onde:
- `t1..tN` — durações em microsegundos
- `m1..mN` — modos (inteiro), decomposto em bits:
  - Bit 0 → d4
  - Bit 1 → d5
  - Bit 2 → d6

**Exemplo:** `SIGNAL:10,20,10,20;7,0,7,0` configura um padrão de 4 segmentos alternando todos os pinos ligados (modo 7 = 111) e desligados (modo 0 = 000).

---

## Fluxo de Dados e Controle

### Fluxo de Inicialização

```
app_main()
  ├── Verifica CPU freq (ideal 240 MHz)
  ├── app_init()
  │   ├── led_init()
  │   ├── analog_init()            → ADC1, 6 canais
  │   ├── signal_controller_init() → GPIOs + padrão default (SET_A)
  │   ├── nvs_flash_init()
  │   ├── ble_controller_init()    → BT Controller → Bluedroid → GAP → GATTS
  │   └── xSemaphoreCreateBinary() → sem_analog_read_trigger
  ├── xTaskCreatePinnedToCore(analog_reading_task, Core 0)
  ├── xTaskCreatePinnedToCore(analog_action_task, Core 0)
  ├── matrix_test()
  └── blink(4)                     → Feedback visual: boot OK
```

### Fluxo de Geração de Sinal

```
Comando "start" via BLE
  └── signal_start_continuous()
      └── xTaskCreatePinnedToCore(signal_loop_task, Core 1, prio 10)
          ├── portDISABLE_INTERRUPTS()
          └── Loop:
              ├── Verificar g_ds_update_pending → swap buffers
              ├── Para cada segmento i:
              │   ├── Calcular transições (d4, d5, d6 vs last)
              │   ├── Se houve transição:
              │   │   ├── GPIO.out_w1tc = clear_mask  (dead time)
              │   │   ├── helper_delay_cycles(g_cycle_us_delay_up/down)
              │   │   └── GPIO.out_w1ts = set_mask    (novo estado)
              │   ├── Se não:
              │   │   └── GPIO.out_w1ts = set_mask    (manter)
              │   ├── esp_rom_delay_us(duração)
              │   └── Se i==0 e BLE read habilitado:
              │       └── Incrementar ciclo → semáforo → analog_action_task
              └── Até g_system_state.signal_state != RUNNING
```

### Fluxo de Atualização de Alpha

```
Comando "SET_ALPHA:0.15" via BLE
  └── ble_router_message_set_alpha(message)
      ├── Identifica dataset inativo (se A ativo → escreve em B)
      ├── helper_set_dataset_from_alpha(dataset, 0.15)
      │   └── Preenche time_durations, modes, target, gain_k
      └── g_ds_update_pending = true
          └── signal_loop_task detecta no próximo ciclo → swap
```

---

## Estruturas de Dados Principais

### `SystemState`
```cpp
struct SystemState {
    SignalState signal_state;           // IDLE | RUNNING
    BLEAnalogReadState ble_an_read_state; // IDLE | READING | DISABLED
};
```

### `DataSet`
```cpp
struct DataSet {
    uint32_t time_durations[100];  // Duração de cada segmento (µs)
    uint32_t modes_d4[100];        // Estado do pino d4/d4' por segmento
    uint32_t modes_d5[100];        // Estado do pino d5/d5' por segmento
    uint32_t modes_d6[100];        // Estado do pino d6/d6' por segmento
    uint32_t size;                 // Número de segmentos ativos
    int32_t  time_us_diff[100];    // Diferenças de tempo (reservado)
    float    target[3];            // Vetor alvo de controle [3×1]
    MatrixData gain_k;             // Matriz de ganho K (tipicamente 5×3)
};
```

### `MatrixData`
```cpp
struct MatrixData {
    float values[100];   // Elementos da matriz (row-major)
    uint16_t size;       // Total de elementos (rows × cols)
    uint16_t rows, cols; // Dimensões
    bool is_valid;       // Flag de validação
};
```

### `NoteData`
```cpp
struct NoteData {
    char* buffer;    // Buffer dinâmico de texto
    size_t size;     // Tamanho total alocado
    size_t idx;      // Índice de escrita atual
    bool is_full;    // Flag de overflow
};
```

### `LogDuration`
```cpp
struct LogDuration {
    int64_t read_and_send_analog_us;  // Tempo leitura+envio analógico
    int64_t matrix_multiply_us;       // Tempo multiplicação matricial
    int64_t dtk_condition;            // Tempo condição dtk
    int64_t update_signal_with_dtk;   // Tempo atualização de sinal
};
```

---

## Tarefas FreeRTOS

| Tarefa | Core | Prioridade | Stack | Descrição |
|--------|------|------------|-------|-----------|
| `analog_reading_task` | 0 | `tskIDLE + 1` | 8 KB | Monitoração analógica periódica (AN3, AN5, AN6) com envio via BLE |
| `analog_action_task` | 0 | `tskIDLE + 1` | 4 KB | Leitura analógica sob demanda (via semáforo), triggered pelo signal loop |
| `blink_task` | qualquer | 5 | 2 KB | Blink do LED com delays configuráveis (criada/destruída por comando BLE) |
| `signal_loop_task` | 1 | 10 | 4 KB | Loop de geração de sinais com interrupções desabilitadas |

### Sincronização

| Mecanismo | Tipo | Uso |
|-----------|------|-----|
| `sem_analog_read_trigger` | Semáforo binário | signal_loop → analog_action_task |
| `g_ds_update_pending` | volatile bool | BLE task → signal_loop_task |
| `g_system_state` | volatile struct | Compartilhado entre todas as tasks |

---

## Como Compilar e Gravar

### Pré-requisitos

- **ESP-IDF v5.5.1** instalado em `$env:USERPROFILE/esp/v5.5.1/esp-idf`
- ESP32 conectado via USB (COM port)

### Setup do Ambiente (PowerShell)

```powershell
# Instalar dependências (primeira vez)
. $env:USERPROFILE/esp/v5.5.1/esp-idf/install.ps1

# Exportar variáveis de ambiente (a cada sessão)
. $env:USERPROFILE/esp/v5.5.1/esp-idf/export.ps1
```

### Definir Target

```powershell
idf.py set-target esp32
```

### Build, Flash e Monitor

```powershell
idf.py build
idf.py flash -p COM11
idf.py monitor -p COM11
```

Ou tudo de uma vez:

```powershell
idf.py -p COM11 flash monitor
```

Para sair do monitor: `Ctrl-]`

### Comando Rápido (Build + Flash + Monitor)

```powershell
. $env:USERPROFILE/esp/v5.5.1/esp-idf/export.ps1; idf.py build; idf.py flash; idf.py monitor -p COM11;
```

---

## Usar Web Bluetooth no Brave

Para conectar ao ESP32 via Web Bluetooth no Brave, habilite os recursos experimentais:

1. Abra `brave://flags/#enable-experimental-web-platform-features`.
2. Altere **Experimental Web Platform features** para **Enabled**.
3. Reinicie o Brave.
4. Abra `brave://settings/content/bluetoothDevices` e confirme que permissões de Bluetooth estão habilitadas.
5. Desative o **Shields** do Brave para a página que acessa o BLE, se a conexão continuar bloqueada.

Se a página estiver em HTTP, use uma origem segura:

- Preferencial: `http://localhost:<porta>`.
- Para IP/rede local, iniciar o Brave com a origem marcada como segura:

```powershell
& "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" `
  --unsafely-treat-insecure-origin-as-secure=http://192.168.0.10:8000 `
  --user-data-dir="$env:TEMP\brave-ble-test"
```

Substitua `http://192.168.0.10:8000` pela origem exata da página, incluindo porta.

---

## Configuração

### sdkconfig.defaults

| Configuração | Valor | Descrição |
|--------------|-------|-----------|
| `CONFIG_BT_ENABLED` | `y` | Bluetooth habilitado |
| `CONFIG_BT_BLE_50_FEATURES_SUPPORTED` | `n` | BLE 5.0 desabilitado |
| `CONFIG_BT_BLE_42_FEATURES_SUPPORTED` | `y` | BLE 4.2 habilitado |

### Kconfig (menuconfig)

- **Opção:** `EXAMPLE_SET_RAW_ADV_DATA` — usar dados brutos para advertising (mais controle, menor overhead)
- **CPU Frequency:** Recomendado 240 MHz (`Component config → ESP System Settings → CPU frequency`)

---

## TODO / Roadmap

| Status | Tarefa |
|--------|--------|
| ✅ | Implementar analog_read |
| ✅ | Enviar dados analógicos via BLE |
| ❌ | ~~Implementar print on/off~~ (cancelado) |
| ✅ | Implementar set_alpha |
| ✅ | Implementar matrizes |
| ✅ | Implementar leitura de sinal a cada N ciclos |
| ⬜ | **Implementar medições de tempo** |
| ✅ | Remover spline da curva do gráfico |
| ✅ | Ajustar datasetter no MATLAB para formato ajustado |
| ⬜ | **Implementar ação de controle** |
| ✅ | Implementar mensagem de status |
| ✅ | Implementar mensagem de matriz (A e B) |

---

## Licença

Copyright 2025 ITA (Instituto Tecnológico de Aeronáutica). Licensed under the MIT license.

Partes do código BLE baseadas em exemplos da Espressif Systems (Unlicense / CC0-1.0).
