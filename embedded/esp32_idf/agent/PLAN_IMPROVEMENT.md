# Plano de Melhorias — ESP32 BLE Signal Controller

> **Documento de análise técnica e roadmap de melhorias**
> Gerado em: 2025-01-10

---

## Índice

1. [Resumo Executivo](#resumo-executivo)
2. [Pontos Críticos de Atenção](#-pontos-críticos-de-atenção)
3. [Pontos de Melhoria](#-pontos-de-melhoria)
4. [Aspectos Positivos](#-aspectos-positivos)
5. [Priorização e Esforço](#priorização-e-esforço)
6. [Referências](#referências)

---

## Resumo Executivo

Este documento apresenta uma análise técnica do projeto ESP32 BLE Signal Controller, identificando pontos críticos que requerem atenção imediata, oportunidades de melhoria de código e arquitetura, e aspectos positivos que devem ser mantidos.

O projeto implementa um controlador de sinais digitais em tempo real com:
- Arquitetura dual-core (Core 0: BLE/ADC, Core 1: Geração de sinal)
- Double-buffering de datasets (swap A/B)
- Controle em malha fechada com multiplicação matricial
- Interface BLE para configuração e telemetria

---

## 🔴 Pontos Críticos de Atenção

### 1. Interrupções Desabilitadas no Loop de Sinal

**Arquivo:** `main/src/signal_controller.cpp` (linhas ~185-186)

**Problema:**
```cpp
portDISABLE_INTERRUPTS();
// ... loop inteiro de geração de sinal ...
portENABLE_INTERRUPTS();
```

O loop de geração de sinal executa completamente com interrupções desabilitadas. Isso pode causar:
- **Timeout do Watchdog** se os padrões de sinal forem muito longos
- **Desconexão BLE** devido a violação de timing do protocolo
- **Instabilidade do sistema** se o loop travar

**Recomendação:**
- Manter seções críticas mínimas — desabilitar interrupções apenas nas operações de toggle GPIO
- Implementar mecanismo de "yield" periódico dentro do loop
- Considerar uso de `taskYIELD()` ou `portYIELD_FROM_ISR()` quando seguro

**Prioridade:** 🔴 Alta

---

### 2. Acesso a Estado Global Sem Sincronização

**Arquivo:** `main/include/helper_common.h`

**Problema:**
Múltiplas variáveis globais `volatile` são acessadas entre cores sem operações atômicas:
- `g_adc_an3`, `g_adc_an5`, `g_adc_an6` (floats de 32 bits)
- `g_control_enabled` (bool)
- `g_active_set` (enum)

No ESP32 (arquitetura Xtensa), escritas de floats/enums de 32 bits não são atômicas. Acesso concorrente pode causar leituras parciais (torn reads).

**Recomendação:**
```cpp
// Substituir:
extern volatile float g_adc_an3;
// Por:
#include <atomic>
extern std::atomic<float> g_adc_an3;
```

**Prioridade:** 🔴 Alta

---

### 3. Gerenciamento de Memória no `NoteData`

**Arquivo:** `main/include/helper_note.h` (linhas ~44-47)

**Problema:**
```cpp
NoteData() : size(NOTE_BUFFER_SIZE), idx(0), is_full(false) {
    buffer = new char[size];
    std::fill(buffer, buffer + size, '\0');
}
```

Uso de `new/delete` em sistemas embarcados pode causar fragmentação de heap ao longo do tempo.

**Recomendação:**
- Usar alocação estática para buffers de tamanho fixo
- Implementar memory pool para objetos `NoteData`
- Considerar `std::array` ou buffers pré-alocados

**Prioridade:** 🟡 Média

---

### 4. Tratamento de Erros na Calibração ADC

**Arquivo:** `main/src/helper_analog.cpp` (linhas ~52-82)

**Problema:**
A tabela de calibração possui valores hardcoded sem validação adequada dos limites de interpolação.

**Recomendação:**
- Adicionar assertions em debug mode
- Implementar detecção de falha do sensor (valores fora do range esperado)
- Logar warnings quando valores estiverem próximos aos limites

**Prioridade:** 🟡 Média

---

### 5. Tamanho de Stack das Tasks

**Arquivo:** `main/main.cpp` (linhas ~125-126)

**Problema:**
A task de leitura analógica usa 8KB de stack devido ao uso de `helper::printf`. Embora aceitável, deve ser monitorado.

**Recomendação:**
- Adicionar monitoramento de stack: `uxTaskGetStackHighWaterMark()`
- Implementar warning no log se stack restante < 20%
- Considerar refatorar para reduzir uso de stack

**Prioridade:** 🟡 Média

---

## 🟡 Pontos de Melhoria

### 1. Refatorar `helper_datasetter.cpp`

**Arquivo:** `main/src/helper_datasetter.cpp` (~4.100 linhas)

**Problema:**
O arquivo contém uma função massiva com valores hardcoded para cada valor de alpha (0.10 a 4.00), resultando em:
- Código difícil de manter
- Tamanho de binário inflado
- Dificuldade para adicionar novos valores de alpha

**Recomendação:**
- **Opção A:** Gerar dados em tempo de build a partir de script MATLAB/Python
- **Opção B:** Armazenar dados em flash como tabela binária
- **Opção C:** Implementar interpolação entre valores conhecidos de alpha

**Estrutura sugerida:**
```
data/
  datasets/
    alpha_0.10.bin
    alpha_0.11.bin
    ...
tools/
  generate_datasets.py  # Script para gerar dados
```

**Prioridade:** 🟡 Média | **Esforço:** Alto

---

### 2. Duplicação do Algoritmo de Controle

**Arquivos:** 
- `main/include/control_action.h` (header-only, inlined)
- `main/src/signal_controller.cpp` (linhas ~225-250)

**Problema:**
A lógica de controle está duplicada em dois locais, criando risco de divergência.

**Recomendação:**
- Consolidar em uma única implementação
- Manter a abordagem header-only para performance, mas remover duplicação
- Adicionar testes unitários para validar consistência

**Prioridade:** 🟡 Média | **Esforço:** Baixo

---

### 3. Números Mágicos e Configuração

**Arquivo:** `main/src/signal_controller.cpp` (linhas ~54-55)

**Problema:**
```cpp
volatile uint32_t g_dead_time_cycles_up = 215;
volatile uint32_t g_dead_time_cycles_down = 215;
```

Múltiplos valores hardcoded sem documentação clara.

**Recomendação:**
- Definir constantes com nomes descritivos:
```cpp
// Dead time de ~900ns a 240MHz para proteção de switching
constexpr uint32_t DEAD_TIME_CYCLES_UP_DEFAULT = 215;
constexpr uint32_t DEAD_TIME_CYCLES_DOWN_DEFAULT = 215;
```
- Expor via comandos BLE para ajuste em runtime
- Adicionar validação contra limites mínimos do hardware

**Prioridade:** 🟡 Média | **Esforço:** Baixo

---

### 4. Otimizar Router BLE

**Arquivo:** `main/src/ble_controller.cpp` (linhas ~160-243)

**Problema:**
O router usa comparação de strings com `strncmp` para cada comando, resultando em O(n) por lookup.

**Recomendação:**
- Implementar lookup table com hash
- Usar `std::unordered_map` ou array de structs com busca binária
- Exemplo:
```cpp
struct BLECommand {
    const char* prefix;
    uint8_t prefix_len;
    std::function<void(const std::string&)> handler;
};

static const BLECommand commands[] = {
    {"SIGNAL:", 7, handle_signal},
    {"BLINK:", 6, handle_blink},
    // ...
};
```

**Prioridade:** 🟢 Baixa | **Esforço:** Médio

---

### 5. Precisão na Medição de Tempo

**Arquivo:** `main/include/control_action.h` (linha ~30)

**Problema:**
```cpp
g_log_duration.dtk_condition = (t3 - t2) / 240;
```

Assume frequência constante de 240MHz, mas a frequência pode variar.

**Recomendação:**
- Usar `esp_timer_get_time()` para medição portável
- Ou obter frequência real: `esp_clk_cpu_freq() / 1e6`

**Prioridade:** 🟢 Baixa | **Esforço:** Baixo

---

### 6. Infraestrutura de Testes

**Diretório:** `sandbox/`

**Problema:**
- Sem runner de testes automatizado
- Sem configuração CI/CD
- Código de teste duplica lógica de produção

**Recomendação:**
- Configurar framework de testes Unity (nativo ESP-IDF)
- Criar testes unitários para:
  - `matrix_multiply_vector3()`
  - `condition_dtk()`
  - `compute_duration_corrections()`
  - Parsing de sinais BLE
- Adicionar GitHub Actions para build automatizado

**Prioridade:** 🟢 Baixa | **Esforço:** Médio

---

### 7. Documentação Técnica

**Problema:**
Áreas que precisam de documentação adicional:
- Fundamentos teóricos de controle (o que é alpha? quais são os targets?)
- Diagramas de timing para geração de sinal
- Especificação do protocolo BLE (formatos de mensagem)

**Recomendação:**
- Adicionar seção "Teoria de Controle" no README
- Criar diagramas com Mermaid ou draw.io
- Documentar protocolo BLE em formato formal

**Prioridade:** 🟢 Baixa | **Esforço:** Médio

---

### 8. Debug Code Remanescente

**Arquivo:** `main/main.cpp` (linhas ~105-106)

**Problema:**
```cpp
ESP_LOGE("mijn test", "ik ben hier, u haaaa");
ESP_LOGE("mijn test", "ik ben hier, u haaaa");
```

Código de debug em produção.

**Recomendação:**
- Remover logs de debug antes de release
- Implementar macros de debug condicionais:
```cpp
#ifdef DEBUG_BUILD
    #define DEBUG_LOG(tag, fmt, ...) ESP_LOGI(tag, fmt, ##__VA_ARGS__)
#else
    #define DEBUG_LOG(tag, fmt, ...) ((void)0)
#endif
```

**Prioridade:** 🟢 Baixa | **Esforço:** Baixo

---

## 🟢 Aspectos Positivos

### Boas Práticas Identificadas

1. **Separação clara de responsabilidades** entre módulos (BLE, analog, signal, matrix)
2. **Pattern de double-buffering** bem implementado para datasets de sinal
3. **Uso adequado de C++ moderno** (unique_ptr, enums com class scope, RAII)
4. **Documentação abrangente** no README (634 linhas)
5. **Mapeamento completo de pinos** e documentação de hardware
6. **Setup de DevContainer** para ambiente de desenvolvimento reprodutível
7. **Configuração de clang-format** para estilo de código consistente
8. **Uso de Kconfig** para configuração em tempo de build

### Padrões que Devem Ser Mantidos

- Estrutura de diretórios lógica (`main/include/`, `main/src/`)
- Convenção de nomes (`g_` para globals, `s_` para statics)
- Documentação inline em funções críticas
- Uso de `esp_err_t` para tratamento de erros

---

## Priorização e Esforço

| Prioridade  | Item                                                 | Esforço | Impacto          |
| ----------  | ---------------------------------------------------- | ------- | ---------------- |
| 🔴 Alta     | Minimizar seções com interrupções desabilitadas      | Médio   | Estabilidade     |
| 🔴 Alta     | Adicionar proteção atômica para estado compartilhado | Baixo   | Confiabilidade   |
| 🟡 Média    | Refatorar datasetter para dados externos             | Alto    | Manutenibilidade |
| 🟡 Média    | Consolidar algoritmo de controle                     | Baixo   | Manutenibilidade |
| 🟡 Média    | Configuração runtime de dead-time                    | Baixo   | Flexibilidade    |
| 🟡 Média    | Monitoramento de stack usage                         | Baixo   | Debugging        |
| 🟢 Baixa    | Setup de testes automatizados                        | Médio   | Qualidade        |
| 🟢 Baixa    | Melhorar medição de tempo                            | Baixo   | Precisão         |
| 🟢 Baixa    | Otimizar router BLE                                  | Médio   | Performance      |
| 🟢 Baixa    | Remover código de debug                              | Baixo   | Limpeza          |
| 🟢 Baixa    | Expandir documentação técnica                        | Médio   | Conhecimento     |

---

## Referências

- [ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [FreeRTOS Documentation](https://www.freertos.org/Documentation/RTOS_book.html)
- [ESP32 Technical Reference Manual](https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf)
- Projeto: `doc/prompt_control_flow.md`

---

*Este documento deve ser revisado periodicamente conforme o projeto evolui.*