# Потоковый арбитр с политикой QoS

Репозиторий содержит решение тестового задания **"Потоковый арбитр с политикой Quality-of-Service (QoS)"**.

Арбитр принимает `STREAM_COUNT` параллельных потоков и выбирает транзакцию:
- с **максимальным приоритетом** `s_qos_i` (чем больше — тем выше приоритет);
- при равных приоритетах — по схеме **Round-Robin**;
- приоритет `0` не участвует в сравнении, но такие транзакции обслуживаются **наравне с максимальным приоритетом** по Round-Robin.

Арбитраж **потранзакционный**: переключение на следующий поток происходит только после завершения текущей транзакции (`last`).

---

## Структура репозитория

- `Потоковый арбитр с политикой Quolity.pdf` — отчёт по проектированию, микроархитектура, анализ синтеза.
- `src/`
  - `stream_arbiter.sv` — топ-модуль арбитра.
  - подмодули: Round-Robin арбитр, логика выбора по QoS, ready-логика и т.п.
- `sim/`
  - testbench для ModelSim.
  - текстовые вектора, покрывающие основные паттерны поведения (равные приоритеты, QoS=0, сбой транзакции, отсутствие валидных входов, m_ready_i=0 и т.д.).
- `synth/`
  - XDC/constraints и настройки для тестового синтеза (Vivado / FPGA-под устройство из задания).

---

## Интерфейс модуля

```systemverilog
module stream_arbiter #(
  parameter T_DATA_WIDTH  = 8,
  parameter T_QOS_WIDTH   = 4,
  parameter STREAM_COUNT  = 2,
  localparam T_ID_WIDTH   = $clog2(STREAM_COUNT)
)(
  input  logic                          clk,
  input  logic                          rst_n,
  // input streams
  input  logic [T_DATA_WIDTH-1:0]       s_data_i  [STREAM_COUNT-1:0],
  input  logic [T_QOS_WIDTH-1:0]        s_qos_i   [STREAM_COUNT-1:0],
  input  logic [STREAM_COUNT-1:0]       s_last_i,
  input  logic [STREAM_COUNT-1:0]       s_valid_i,
  output logic [STREAM_COUNT-1:0]       s_ready_o,
  // output stream
  output logic [T_DATA_WIDTH-1:0]       m_data_o,
  output logic [T_QOS_WIDTH-1:0]        m_qos_o,
  output logic [T_ID_WIDTH-1:0]         m_id_o,
  output logic                          m_last_o,
  output logic                          m_valid_o,
  input  logic                          m_ready_i
);
```

---

## Запуск тестов в ModelSim

Testbench поддерживает два режима генерации входов и два режима проверки:

| Режим | Описание |
|-------|----------|
| **GEN_MOD = FILE** | Подача данных из файлов `streamX.txt` |
| **GEN_MOD = RANDOM** | Рандомная генерация потоков |
| **CHECK_MOD = FILE** | Проверка по эталонному файлу `check_vector.txt` |
| **CHECK_MOD = AUTO** | Автоматическая проверка поведения |

### Команды запуска

#### RANDOM‑генерация + AUTO‑проверка
```bash
vsim -c work.testbench \
     -do "vlog +define+GEN_MOD=RANDOM +define+CHECK_MOD=AUTO testbench.sv; \
          vlog stream_arbiter.sv interface.sv; \
          vsim work.testbench; \
          run -all"
```
#### FILE‑генерация + FILE‑проверка
```bash
vsim -c work.testbench \
     -do "vlog +define+GEN_MOD=FILE +define+CHECK_MOD=FILE testbench.sv; \
          vlog stream_arbiter.sv interface.sv; \
          vsim work.testbench; \
          run -all"
```
