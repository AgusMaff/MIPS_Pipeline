# Unidad de Debug

## Descripción General

La unidad de debug es un componente esencial del procesador MIPS que permite el control, monitoreo y depuración del pipeline a través de una interfaz UART. Proporciona capacidades de carga de instrucciones, control de ejecución, y lectura de estado interno del procesador.

## Arquitectura del Módulo

```mermaid
graph TD
    A[UART Interface] --> B[debug_unit<br/>Main Controller]
    B --> C[FSM<br/>State Machine]
    C --> D[Command Decoder]
    
    D --> E[Load Instruction]
    D --> F[Run Pipeline]
    D --> G[Reset System]
    D --> H[Read Data]
    
    E --> I[Instruction Memory<br/>Write]
    F --> J[Pipeline Control<br/>Start/Stop]
    G --> K[System Reset<br/>All Modules]
    H --> L[Data Reading<br/>Registers/Memory]
    
    M[UART RX] --> N[Command Buffer]
    N --> O[Command Processing]
    O --> P[Response Generation]
    P --> Q[UART TX]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style I fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style J fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style K fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style L fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style M fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style N fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style O fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style P fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style Q fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
```

## Módulos Componentes

### 1. debug_unit.v - Controlador Principal

**Descripción**: Módulo principal que coordina todas las operaciones de debug.

**Funcionalidades**:
- Máquina de estados finitos (FSM)
- Decodificación de comandos UART
- Control de carga de instrucciones
- Monitoreo de estado del pipeline
- Generación de respuestas

**Interfaces**:
```verilog
module debug_unit(
    input wire clk,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_done,
    input wire tx_busy,
    input wire [31:0] reg_data,
    input wire [31:0] mem_data,
    input wire [31:0] latch_data,
    input wire halt_signal,
    output reg [7:0] tx_data,
    output reg tx_start,
    output reg [31:0] inst_addr,
    output reg [31:0] inst_data,
    output reg inst_write,
    output reg [4:0] reg_addr,
    output reg [31:0] mem_addr,
    output reg run_signal,
    output reg reset_signal
);
```

**Diagrama de Estados FSM**:
```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> START : Command Received
    START --> LOAD_INSTRUCTION : Load Cmd (0x02)
    START --> RUN : Run Cmd (0x05)
    START --> RESET : Reset Cmd (0x0C)
    START --> READ_REG : Read Reg Cmd (0x03)
    START --> READ_MEM : Read Mem Cmd (0x04)
    START --> READ_LATCH : Read Latch Cmd (0x06)
    
    LOAD_INSTRUCTION --> SEND_ACK : Instruction Loaded
    SEND_ACK --> WRITE_INST : ACK Sent
    WRITE_INST --> IDLE : Write Complete
    
    RUN --> SEND_REG : Running
    SEND_REG --> SEND : Register Data Sent
    SEND --> SEND_M : Continue
    SEND_M --> SEND_REG_INT : Memory Data Sent
    SEND_REG_INT --> WAIT_RX : Internal Data Sent
    WAIT_RX --> WAIT_TX : Data Received
    WAIT_TX --> IDLE : Data Transmitted
    
    RESET --> IDLE : Reset Complete
    
    READ_REG --> SEND_REG_DATA : Register Read
    READ_MEM --> SEND_MEM_DATA : Memory Read
    READ_LATCH --> SEND_LATCH_DATA : Latch Read
    
    SEND_REG_DATA --> IDLE : Data Sent
    SEND_MEM_DATA --> IDLE : Data Sent
    SEND_LATCH_DATA --> IDLE : Data Sent
    
    note right of IDLE
        Waiting for UART commands
    end note
    
    note right of LOAD_INSTRUCTION
        Loading instruction
        into instruction memory
    end note
    
    note right of RUN
        Executing MIPS
        pipeline
    end note
```

### 2. UART.v - Interfaz de Comunicación

**Descripción**: Módulo principal de UART que maneja la comunicación serial.

**Características**:
- Configuración de baud rate
- Recepción y transmisión de datos
- Buffers FIFO para datos
- Control de flujo

**Interfaces**:
```verilog
module UART(
    input wire clk,
    input wire reset,
    input wire rx,
    input wire [7:0] tx_data,
    input wire tx_start,
    output wire tx,
    output wire [7:0] rx_data,
    output wire rx_done,
    output wire tx_busy
);
```

**Diagrama de Arquitectura UART**:
```mermaid
graph TD
    A[UART Interface] --> B[uart_rx<br/>Receiver]
    A --> C[uart_tx<br/>Transmitter]
    A --> D[baud_rate_gen<br/>Clock Generator]
    A --> E[fifo<br/>Buffer]
    
    B --> F[RX FIFO]
    C --> G[TX FIFO]
    D --> H[UART Clock]
    
    F --> I[Debug Unit]
    I --> G
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style I fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
```

### 3. uart_rx.v - Receptor UART

**Descripción**: Módulo que recibe datos seriales y los convierte a paralelo.

**Funcionalidades**:
- Detección de start/stop bits
- Muestreo de datos
- Validación de paridad
- Generación de señales de control

**Interfaces**:
```verilog
module uart_rx(
    input wire clk,
    input wire reset,
    input wire rx,
    input wire baud_clk,
    output reg [7:0] data,
    output reg done
);
```

### 4. uart_tx.v - Transmisor UART

**Descripción**: Módulo que convierte datos paralelos a seriales para transmisión.

**Funcionalidades**:
- Generación de start/stop bits
- Transmisión de datos
- Control de timing
- Señales de estado

**Interfaces**:
```verilog
module uart_tx(
    input wire clk,
    input wire reset,
    input wire [7:0] data,
    input wire start,
    input wire baud_clk,
    output reg tx,
    output reg busy
);
```

### 5. baud_rate_gen.v - Generador de Baud Rate

**Descripción**: Genera el reloj necesario para la comunicación UART.

**Funcionalidad**:
- División de frecuencia
- Configuración de baud rate
- Sincronización de reloj

**Interfaces**:
```verilog
module baud_rate_gen(
    input wire clk,
    input wire reset,
    output reg baud_clk
);
```

### 6. fifo.v - Buffer FIFO

**Descripción**: Buffer de datos para almacenamiento temporal.

**Características**:
- Almacenamiento FIFO
- Control de overflow/underflow
- Indicadores de estado

**Interfaces**:
```verilog
module fifo(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire write_en,
    input wire read_en,
    output wire [7:0] data_out,
    output wire full,
    output wire empty
);
```

## Comandos UART Soportados

### Tabla de Comandos
```mermaid
graph TD
    A[Command Byte] --> B{Command Type}
    B -->|0x02| C[Load Instruction]
    B -->|0x03| D[Read Register]
    B -->|0x04| E[Read Memory]
    B -->|0x05| F[Run Pipeline]
    B -->|0x06| G[Read Latch]
    B -->|0x0C| H[Reset System]
    
    C --> I[Send Address + Data]
    D --> J[Send Register Number]
    E --> K[Send Memory Address]
    F --> L[Start Execution]
    G --> M[Send Latch ID]
    H --> N[System Reset]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
```

### Protocolo de Comunicación
```mermaid
sequenceDiagram
    participant Host as Host PC
    participant UART as UART Interface
    participant Debug as Debug Unit
    participant Pipeline as MIPS Pipeline
    
    Host->>UART: Send Command
    UART->>Debug: Command Data
    Debug->>Debug: Process Command
    
    alt Load Instruction
        Debug->>Pipeline: Write Instruction
        Debug->>UART: Send ACK
    else Run Pipeline
        Debug->>Pipeline: Start Execution
        Debug->>UART: Send Status
    else Read Data
        Debug->>Pipeline: Read Request
        Pipeline->>Debug: Data
        Debug->>UART: Send Data
    end
    
    UART->>Host: Response
```

## Flujo de Datos Detallado

### Carga de Instrucciones
```mermaid
sequenceDiagram
    participant Host as Host PC
    participant UART as UART Interface
    participant Debug as Debug Unit
    participant IMEM as Instruction Memory
    
    Host->>UART: 0x02 (Load Command)
    UART->>Debug: Command Received
    Debug->>Debug: State: LOAD_INSTRUCTION
    
    Host->>UART: Address (4 bytes)
    UART->>Debug: Address Data
    Debug->>Debug: Store Address
    
    Host->>UART: Instruction (4 bytes)
    UART->>Debug: Instruction Data
    Debug->>IMEM: Write Instruction
    Debug->>UART: 0xAA (ACK)
    UART->>Host: ACK Sent
    
    Debug->>Debug: State: IDLE
```

### Ejecución del Pipeline
```mermaid
sequenceDiagram
    participant Host as Host PC
    participant UART as UART Interface
    participant Debug as Debug Unit
    participant Pipeline as MIPS Pipeline
    
    Host->>UART: 0x05 (Run Command)
    UART->>Debug: Command Received
    Debug->>Debug: State: RUN
    
    Debug->>Pipeline: Start Execution
    Pipeline->>Debug: HALT Signal
    
    Debug->>Debug: State: SEND_REG
    Debug->>Pipeline: Read Registers
    Pipeline->>Debug: Register Data
    Debug->>UART: Send Register Data
    UART->>Host: Register Data
    
    Debug->>Debug: State: SEND_M
    Debug->>Pipeline: Read Memory
    Pipeline->>Debug: Memory Data
    Debug->>UART: Send Memory Data
    UART->>Host: Memory Data
    
    Debug->>Debug: State: IDLE
```

### Lectura de Datos
```mermaid
sequenceDiagram
    participant Host as Host PC
    participant UART as UART Interface
    participant Debug as Debug Unit
    participant Pipeline as MIPS Pipeline
    
    Host->>UART: 0x03 (Read Register)
    UART->>Debug: Command Received
    
    Host->>UART: Register Number
    UART->>Debug: Register Address
    Debug->>Pipeline: Read Register
    Pipeline->>Debug: Register Data
    Debug->>UART: Send Data
    UART->>Host: Register Data
```

## Estados de la FSM

### Diagrama de Estados Detallado
```mermaid
graph TD
    A[IDLE] --> B[START]
    B --> C[LOAD_INSTRUCTION]
    B --> D[RUN]
    B --> E[RESET]
    B --> F[READ_REG]
    B --> G[READ_MEM]
    B --> H[READ_LATCH]
    
    C --> I[SEND_ACK]
    I --> J[WRITE_INST]
    J --> A
    
    D --> K[SEND_REG]
    K --> L[SEND]
    L --> M[SEND_M]
    M --> N[SEND_REG_INT]
    N --> O[WAIT_RX]
    O --> P[WAIT_TX]
    P --> A
    
    E --> A
    
    F --> Q[SEND_REG_DATA]
    G --> R[SEND_MEM_DATA]
    H --> S[SEND_LATCH_DATA]
    
    Q --> A
    R --> A
    S --> A
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style I fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style J fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style K fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style L fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style M fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style N fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style O fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style P fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style Q fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style R fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style S fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
```

## Integración con el Pipeline

### Conexiones con Etapas del Pipeline
```mermaid
graph TD
    A[Debug Unit] --> B[IF Stage<br/>Instruction Memory]
    A --> C[ID Stage<br/>Register File]
    A --> D[EX Stage<br/>ALU Results]
    A --> E[MEM Stage<br/>Data Memory]
    A --> F[WB Stage<br/>Write Back]
    
    A --> G[Pipeline Control<br/>Run/Stop/Reset]
    A --> H[Pipeline Latches<br/>IF/ID, ID/EX, EX/MEM, MEM/WB]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
```

### Señales de Control
```mermaid
graph TD
    A[Debug Unit] --> B[run_signal<br/>Pipeline Start/Stop]
    A --> C[reset_signal<br/>System Reset]
    A --> D[inst_write<br/>Instruction Memory Write]
    A --> E[reg_addr<br/>Register Address]
    A --> F[mem_addr<br/>Memory Address]
    
    G[halt_signal] --> A
    H[reg_data] --> A
    I[mem_data] --> A
    J[latch_data] --> A
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style I fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style J fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
```

## Configuración UART

### Parámetros de Comunicación
```mermaid
graph TD
    A[Baud Rate: 19200] --> B[Clock Division]
    C[Data Bits: 8] --> D[Data Format]
    E[Stop Bits: 1] --> D
    F[Parity: None] --> D
    
    G[FIFO Size: 16 bytes] --> H[Buffer Configuration]
    I[Timeout: 100ms] --> J[Error Handling]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style I fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style J fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
```

## Casos de Uso

### Debug de Programa
```mermaid
graph TD
    A[Load Program] --> B[Set Breakpoints]
    B --> C[Run Pipeline]
    C --> D[Monitor Execution]
    D --> E[Read Registers]
    E --> F[Read Memory]
    F --> G[Analyze Results]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
```

### Verificación de Hazards
```mermaid
graph TD
    A[Load Test Program] --> B[Run Step by Step]
    B --> C[Monitor Pipeline Latches]
    C --> D[Check Forwarding]
    D --> E[Verify Hazards]
    E --> F[Validate Results]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

## Archivos Relacionados

- `debug_unit.v`: Módulo principal de debug
- `UART.v`: Interfaz UART principal
- `uart_rx.v`: Receptor UART
- `uart_tx.v`: Transmisor UART
- `baud_rate_gen.v`: Generador de baud rate
- `fifo.v`: Buffer FIFO
- `testbenchs/uart_test.v`: Testbench de UART 