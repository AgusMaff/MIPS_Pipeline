# MIPS Pipeline Processor

## Descripción General

Este proyecto implementa un procesador MIPS de 5 etapas con pipeline completo, incluyendo unidades de forwarding, hazard detection, y una unidad de debug integrada. El procesador está diseñado para ejecutar instrucciones MIPS básicas y está optimizado para implementación en FPGA.

## Arquitectura del Pipeline

```mermaid
graph LR
    A[IF<br/>Fetch] --> B[ID<br/>Decode]
    B --> C[EX<br/>Execute]
    C --> D[MEM<br/>Memory]
    D --> E[WB<br/>Write Back]
    
    A --> F[IF/ID<br/>Latch]
    B --> G[ID/EX<br/>Latch]
    C --> H[EX/MEM<br/>Latch]
    D --> I[MEM/WB<br/>Latch]
    E --> J[RegFile]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
```

## Estructura del Proyecto

```
MIPS_Pipeline/
├── TOP.v                    # Módulo principal del sistema
├── PIPELINE.v              # Módulo principal del pipeline
├── Basys3_Master.xdc       # Constraints para FPGA Basys3
├── IF/                     # Etapa de Fetch (Instruction Fetch)
├── ID/                     # Etapa de Decode
├── EX/                     # Etapa de Execute
├── Mem/                    # Etapa de Memory
├── WB/                     # Etapa de Write Back
├── SEGREGS/                # Registros de segmentación
├── debugunit/              # Unidad de debug con UART
├── utils/                  # Módulos utilitarios
├── testbenchs/             # Testbenches para verificación
└── py/                     # Interfaz de usuario en Python
```

## Módulos Principales

### 1. TOP.v - Módulo Principal del Sistema

**Descripción**: Módulo de nivel superior que integra el pipeline MIPS con la unidad de debug y el sistema de reloj.

**Funcionalidades**:
- Generación de reloj de 50MHz
- Integración con unidad de debug UART
- Control de LEDs de estado
- Interfaz con FPGA Basys3

**Interfaces**:
- `clock`: Reloj de entrada (100MHz)
- `i_reset`: Señal de reset
- `RsRx/RsTx`: Comunicación UART
- LEDs de estado: `rx_led`, `tx_led`, `idle_led`, `halt_led`, `running_led`

### 2. PIPELINE.v - Módulo Principal del Pipeline

**Descripción**: Implementa el pipeline completo de 5 etapas con todas las unidades de control y forwarding.

**Características**:
- Pipeline de 5 etapas: IF, ID, EX, MEM, WB
- Forwarding unit para evitar hazards de datos
- Hazard detection unit
- Control unit para todas las instrucciones MIPS
- Integración con debug unit

## Etapas del Pipeline

### Etapa IF (Instruction Fetch)

**Módulos**:
- `IF.v`: Controlador principal de la etapa
- `PC.v`: Contador de programa
- `INSMEM.v`: Memoria de instrucciones
- `SHFT2L.v`: Desplazamiento para instrucciones de salto

**Funcionalidades**:
- Lectura de instrucciones desde memoria
- Cálculo de PC+4
- Manejo de saltos (BEQ, JMP)
- Control de stall y flush

**Diagrama de Flujo**:
```mermaid
graph TD
    A[PC] --> B[INSMEM<br/>Instruction Memory]
    B --> C[PC+4<br/>ALU]
    C --> D{MUX BEQ<br/>PCSrc}
    D -->|0| E[Next PC]
    D -->|1| F[BEQ Address]
    F --> G{MUX JMP<br/>Jump}
    G -->|0| E
    G -->|1| H[JMP Address]
    H --> I[SHFT2L<br/>Shift Left 2]
    I --> J[Next PC Final]
    E --> J
    J --> A
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style I fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style J fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
```

### Etapa ID (Instruction Decode)

**Módulos**:
- `ID.v`: Controlador principal de la etapa
- `REGMEM.v`: Banco de registros
- `CONTROL_UNIT.v`: Unidad de control
- `HAZARD_UNIT.v`: Detección de hazards
- `FORWARDING_UNIT_ID.v`: Forwarding para etapa ID
- `SIGN_EXTEND.v`: Extensión de signo
- `SHFT2L_ID.v`: Desplazamiento para BEQ
- `COMPARATOR.V`: Comparador para BEQ
- `AND_ID.v`: Compuerta AND para control

**Funcionalidades**:
- Decodificación de instrucciones
- Lectura de registros
- Generación de señales de control
- Detección de hazards de datos
- Cálculo de dirección de salto para BEQ

**Diagrama de Flujo**:
```mermaid
graph TD
    A[Instruction] --> B[CONTROL_UNIT<br/>Control Signals]
    A --> C[REGMEM<br/>Register File]
    A --> D[SIGN_EXTEND<br/>Immediate]
    
    B --> E[Control Signals]
    C --> F[Data1/Data2]
    D --> G[Extended Immediate]
    
    F --> H[HAZARD_UNIT<br/>Hazard Detection]
    H --> I{Stall?}
    I -->|Yes| J[Stall Pipeline]
    I -->|No| K[Continue]
    
    F --> L[COMPARATOR<br/>BEQ Comparison]
    G --> M[SHFT2L_ID<br/>BEQ Address Calc]
    L --> N[Branch Decision]
    M --> O[BEQ Jump Address]
    
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
```

### Etapa EX (Execute)

**Módulos**:
- `EX.v`: Controlador principal de la etapa
- `ALU.v`: Unidad Aritmético-Lógica
- `ALU_CONTROL.v`: Control de la ALU
- `FORWARDING_UNIT_EX.v`: Forwarding para etapa EX
- `MUX2TO1_EX.v`: Multiplexor 2:1
- `MUX3TO1.v`: Multiplexor 3:1

**Funcionalidades**:
- Ejecución de operaciones aritméticas y lógicas
- Forwarding de datos para evitar hazards
- Selección de operandos
- Cálculo de direcciones de memoria

**Diagrama de Flujo**:
```mermaid
graph TD
    A[Data1/Data2<br/>from ID] --> B[FORWARDING_UNIT_EX<br/>Forward Detection]
    B --> C[MUX3TO1<br/>Forward A]
    B --> D[MUX3TO1<br/>Forward B]
    
    C --> E[Operand A]
    D --> F[Data2]
    F --> G[MUX2TO1<br/>ALU Src]
    
    G -->|0| H[Operand B]
    G -->|1| I[Extended Immediate]
    I --> H
    
    E --> J[ALU<br/>Execute]
    H --> J
    
    B --> K[ALU_CONTROL<br/>Control Signal]
    K --> J
    
    J --> L[ALU Result]
    F --> M[Write Data]
    
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
    style L fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style M fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
```

### Etapa MEM (Memory)

**Módulos**:
- `MEM.v`: Controlador principal de la etapa
- `MEMDATA.v`: Memoria de datos

**Funcionalidades**:
- Acceso a memoria de datos
- Operaciones de load/store
- Control de señales de memoria

**Diagrama de Flujo**:
```mermaid
graph TD
    A[ALU Result<br/>Address] --> B[MEMDATA<br/>Data Memory]
    A --> C[Write Data<br/>from EX]
    
    B --> D{MemRead?}
    D -->|Yes| E[Read Data]
    D -->|No| F[No Read]
    
    C --> G{MemWrite?}
    G -->|Yes| H[Write to Memory]
    G -->|No| I[No Write]
    
    E --> J[Memory Data<br/>to WB]
    A --> K[ALU Result<br/>to WB]
    
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
```

### Etapa WB (Write Back)

**Módulos**:
- `WB.v`: Controlador principal de la etapa

**Funcionalidades**:
- Escritura de resultados en banco de registros
- Selección entre resultado de ALU y datos de memoria

**Diagrama de Flujo**:
```mermaid
graph TD
    A[ALU Result<br/>from MEM] --> B[MUX2TO1<br/>Mem to Reg]
    C[Memory Data<br/>from MEM] --> B
    
    B -->|0| D[Write Data<br/>ALU Result]
    B -->|1| E[Write Data<br/>Memory Data]
    
    D --> F[REGMEM<br/>Write to Register]
    E --> F
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

## Registros de Segmentación

### IF/ID.v
**Descripción**: Registro de segmentación entre etapas IF e ID
**Datos almacenados**:
- PC+4
- Instrucción leída

### ID/EX.v
**Descripción**: Registro de segmentación entre etapas ID y EX
**Datos almacenados**:
- Datos de registros
- Señales de control
- Inmediatos extendidos
- Direcciones de registros

### EX/MEM.v
**Descripción**: Registro de segmentación entre etapas EX y MEM
**Datos almacenados**:
- Resultado de ALU
- Datos a escribir en memoria
- Señales de control de memoria
- Dirección de registro destino

### MEM/WB.v
**Descripción**: Registro de segmentación entre etapas MEM y WB
**Datos almacenados**:
- Datos leídos de memoria
- Resultado de ALU
- Señales de control de escritura
- Dirección de registro destino

## Unidad de Debug

### debug_unit.v
**Descripción**: Unidad de debug completa con interfaz UART
**Funcionalidades**:
- Carga de instrucciones vía UART
- Lectura de estado de registros
- Lectura de estado de memoria
- Control de ejecución (run/stop/reset)
- Monitoreo de pipeline

**Diagrama de Estados de la FSM**:
```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> START : Command Received
    START --> LOAD_INSTRUCTION : Load Cmd (0x02)
    START --> RUN : Run Cmd (0x05)
    START --> RESET : Reset Cmd (0x0C)
    
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

**Diagrama de Flujo Detallado de la Debug Unit**:
```mermaid
graph TD
    A[Start Debug Unit] --> B[Initialize UART]
    B --> C[Wait for Command]
    
    C --> D{Command Type?}
    D -->|0x02| E[Load Instruction]
    D -->|0x05| F[Run Pipeline]
    D -->|0x0C| G[Reset System]
    
    E --> H[Receive Address]
    H --> I[Receive Instruction Data]
    I --> J[Write to Instruction Memory]
    J --> K[Send ACK 0xAA]
    K --> C
    
    F --> L[Start Pipeline Execution]
    L --> M[Monitor HALT Signal]
    M --> N{HALT Detected?}
    N -->|No| O[Continue Execution]
    O --> M
    N -->|Yes| P[Send Register Data]
    
    P --> Q[Send Memory Data]
    Q --> R[Send Pipeline Latches Data]
    R --> S[Wait for Read Request]
    S --> T{Read Request?}
    T -->|Yes| U[Send Requested Data]
    T -->|No| C
    U --> C
    
    G --> V[Reset MIPS Pipeline]
    V --> W[Reset UART Interface]
    W --> C
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style C fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style E fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style F fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style G fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style K fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style P fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style Q fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style R fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style U fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style V fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
```

### Módulos UART
- `UART.v`: Módulo principal de UART
- `uart_rx.v`: Receptor UART
- `uart_tx.v`: Transmisor UART
- `baud_rate_gen.v`: Generador de baud rate
- `fifo.v`: Buffer FIFO para datos

**Arquitectura UART**:
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

## Módulos Utilitarios

### ALU.v
**Descripción**: Unidad Aritmético-Lógica
**Operaciones soportadas**:
- Suma, resta, multiplicación
- AND, OR, XOR, NOR
- Desplazamientos lógicos y aritméticos
- Comparaciones (signed/unsigned)

### MUX2TO1.v
**Descripción**: Multiplexor 2:1 genérico
**Aplicaciones**:
- Selección de operandos
- Selección de direcciones
- Control de flujo

## Instrucciones Soportadas

### Instrucciones Aritméticas
- `ADD`, `ADDI`, `ADDIU`, `ADDU`: Suma
- `SUB`, `SUBU`: Resta
- `MULT`, `MULTU`: Multiplicación

### Instrucciones Lógicas
- `AND`, `ANDI`: AND lógico
- `OR`, `ORI`: OR lógico
- `XOR`, `XORI`: XOR lógico
- `NOR`: NOR lógico

### Instrucciones de Desplazamiento
- `SLL`, `SRL`, `SRA`: Desplazamientos
- `SLLV`, `SRLV`, `SRAV`: Desplazamientos variables

### Instrucciones de Comparación
- `SLT`, `SLTI`: Comparación signed
- `SLTU`, `SLTIU`: Comparación unsigned

### Instrucciones de Salto
- `BEQ`: Salto si igual
- `BNE`: Salto si no igual
- `J`: Salto incondicional
- `JAL`: Salto y enlace

### Instrucciones de Memoria
- `LW`: Load word
- `SW`: Store word
- `LB`, `SB`: Load/Store byte
- `LH`, `SH`: Load/Store halfword

## Características del Pipeline

### Forwarding (Data Hazard Resolution)
- Forwarding desde EX/MEM a EX
- Forwarding desde MEM/WB a EX
- Forwarding desde EX/MEM a ID (para BEQ)

### Hazard Detection
- Detección de hazards de datos
- Stall automático cuando es necesario
- Flush de pipeline para saltos

### Control Unit
- Generación automática de señales de control
- Soporte para todas las instrucciones MIPS básicas
- Control de memoria y registros

## Interfaz de Usuario

### user_interface.py
**Descripción**: Interfaz gráfica en Python para control del procesador
**Funcionalidades**:
- Carga de programas
- Monitoreo de registros
- Visualización de pipeline
- Control de ejecución

## Testbenches

El proyecto incluye testbenches completos para:
- Instrucciones individuales
- Secuencias de instrucciones
- Casos de forwarding
- Casos de hazard detection
- Unidad de debug

## Implementación en FPGA

### Basys3_Master.xdc
**Descripción**: Archivo de constraints para FPGA Basys3
**Configuración**:
- Reloj de 100MHz
- UART a 19200 baudios
- LEDs de estado
- Switches de control

## Uso del Sistema

### 1. Carga de Programa
```bash
# Compilar el proyecto
# Cargar en FPGA
# Usar interfaz Python para cargar instrucciones
```

### 2. Ejecución
```bash
# Enviar comando RUN vía UART
# Monitorear LEDs de estado
# Observar ejecución en tiempo real
```

### 3. Debug
```bash
# Usar comandos UART para:
# - Leer registros
# - Leer memoria
# - Pausar ejecución
# - Resetear sistema
```

## Comandos UART

| Comando | Función |
|---------|---------|
| 0x02 | Cargar instrucción |
| 0x05 | Ejecutar programa |
| 0x0C | Resetear sistema |
| 0xAA | Acknowledgment |

## Especificaciones Técnicas

- **Arquitectura**: MIPS 32-bit
- **Pipeline**: 5 etapas
- **Memoria**: Harvard (separada instrucciones/datos)
- **Registros**: 32 registros de propósito general
- **Reloj**: 50MHz (interno)
- **UART**: 19200 baudios
- **FPGA**: Basys3 (Artix-7)

## Estado del Proyecto

✅ **Completado**:
- Pipeline de 5 etapas
- Forwarding unit
- Hazard detection
- Debug unit con UART
- Testbenches completos
- Implementación en FPGA

🔄 **En Desarrollo**:
- Optimizaciones de rendimiento
- Instrucciones adicionales
- Interfaz gráfica mejorada

## Contribuciones

Este proyecto es desarrollado como parte de un curso de arquitectura de computadores. Las contribuciones son bienvenidas a través de pull requests.

## Licencia

Este proyecto está bajo licencia MIT. Ver archivo LICENSE para más detalles.