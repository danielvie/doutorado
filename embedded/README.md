# Projeto embarcado

Workspace do projeto de doutorado para controle em tempo real com ESP32.

## Estrutura

- [`esp32_idf/`](esp32_idf/) — firmware ESP-IDF, protocolo BLE, interface web e documentação técnica do controlador de sinais.
- [`kicad/`](kicad/) — fontes das placas, bibliotecas de footprints/símbolos e arquivos de fabricação.
- [`docs-hardware/`](docs-hardware/) — pinagens, diagramas de conexão e datasheets de referência.
- [`tests_espressif/`](tests_espressif/) — experimentos independentes com ESP32/PlatformIO.

## Firmware

Consulte [`esp32_idf/README.md`](esp32_idf/README.md) para a arquitetura e os requisitos do firmware. Para listar os comandos disponíveis:

```sh
cd esp32_idf
task --list
```
