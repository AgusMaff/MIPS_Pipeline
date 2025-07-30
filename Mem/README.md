# Etapa MEM (Memory)

## Descripción General

La etapa MEM (Memory) es la cuarta etapa del pipeline MIPS. Su función principal es acceder a la memoria de datos para operaciones de load y store, y preparar los datos para la etapa de write back.

## Arquitectura del Módulo

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
    
    L[Control Signals] --> M[Memory Control]
    M --> B
    
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
```

## Módulos Componentes

### 1. MEMDATA.v - Memoria de Datos

**Descripción**: Memoria RAM que almacena los datos del programa.

**Características**:
- Memoria de lectura/escritura
- Direccionamiento por palabra (32 bits)
- Soporte para byte, halfword y word
- Acceso para debug unit

**Interfaces**:
```verilog
module MEMDATA(
    input wire clk,
    input wire reset,
    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire mem_read,
    input wire mem_write,
    input wire [2:0] bhw_type,
    output reg [31:0] read_data
);
```

**Diagrama de Memoria**:
```mermaid
graph TD
    A[Address] --> B[Address Decoder]
    B --> C[Memory Array<br/>RAM]
    C --> D[Read Data<br/>Output]
    
    E[Write Data] --> F[Write Enable]
    F --> G[Write Control]
    G --> C
    
    H[BHW Type] --> I[Byte/Half/Word<br/>Control]
    I --> J[Data Alignment]
    J --> C
    
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

### 2. MEM.v - Controlador de Memoria

**Descripción**: Módulo principal que controla las operaciones de memoria.

**Funcionalidades**:
- Control de operaciones de memoria
- Manejo de señales de control
- Preparación de datos para WB
- Integración con debug unit

**Interfaces**:
```verilog
module MEM(
    input wire clk,
    input wire reset,
    input wire [31:0] alu_result,
    input wire [31:0] write_data,
    input wire [4:0] rd,
    input wire mem_read,
    input wire mem_write,
    input wire mem_to_reg,
    input wire reg_write,
    input wire [2:0] bhw_type,
    input wire [4:0] du_mem_addr,
    output wire [31:0] read_data,
    output wire [31:0] alu_result_out,
    output wire [4:0] rd_out,
    output wire mem_to_reg_out,
    output wire reg_write_out,
    output wire [31:0] du_mem_data
);
```

**Diagrama de Control**:
```mermaid
graph TD
    A[ALU Result] --> B[Memory Address]
    C[Write Data] --> D[Memory Write]
    E[Control Signals] --> F[Memory Control]
    
    B --> G[MEMDATA]
    D --> G
    F --> G
    
    G --> H[Read Data]
    A --> I[ALU Result Out]
    
    H --> J[MEM/WB Latch]
    I --> J
    
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

## Tipos de Operaciones de Memoria

### Load Operations (Lectura)
```mermaid
graph LR
    A[LW] --> B[Load Word<br/>32 bits]
    C[LH] --> D[Load Halfword<br/>16 bits]
    E[LB] --> F[Load Byte<br/>8 bits]
    G[LHU] --> H[Load Halfword Unsigned]
    I[LBU] --> J[Load Byte Unsigned]
    
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

### Store Operations (Escritura)
```mermaid
graph LR
    A[SW] --> B[Store Word<br/>32 bits]
    C[SH] --> D[Store Halfword<br/>16 bits]
    E[SB] --> F[Store Byte<br/>8 bits]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

## Flujo de Datos Detallado

### Operación Load (LW)
```mermaid
sequenceDiagram
    participant EX as EX Stage
    participant MEM as Memory Stage
    participant MEMDATA as Data Memory
    participant MEM_WB as MEM/WB Latch
    
    EX->>MEM: ALU Result (Address)
    EX->>MEM: Control Signals
    MEM->>MEMDATA: Address + MemRead
    MEMDATA->>MEM: Read Data
    MEM->>MEM_WB: Memory Data
    MEM->>MEM_WB: ALU Result
```

### Operación Store (SW)
```mermaid
sequenceDiagram
    participant EX as EX Stage
    participant MEM as Memory Stage
    participant MEMDATA as Data Memory
    
    EX->>MEM: ALU Result (Address)
    EX->>MEM: Write Data
    EX->>MEM: Control Signals
    MEM->>MEMDATA: Address + Write Data + MemWrite
    MEMDATA->>MEMDATA: Write to Memory
```

### Operación sin Memoria
```mermaid
sequenceDiagram
    participant EX as EX Stage
    participant MEM as Memory Stage
    participant MEM_WB as MEM/WB Latch
    
    EX->>MEM: ALU Result
    EX->>MEM: Control Signals
    MEM->>MEM_WB: ALU Result
    MEM->>MEM_WB: Control Signals
```

## Alineación de Datos

### Alineación de Bytes
```mermaid
graph TD
    A[Byte Address] --> B[Address Alignment]
    B --> C[Byte Select]
    C --> D[Load/Store Byte]
    
    E[Halfword Address] --> F[Address Alignment]
    F --> G[Halfword Select]
    G --> H[Load/Store Halfword]
    
    I[Word Address] --> J[Address Alignment]
    J --> K[Word Select]
    K --> L[Load/Store Word]
    
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
    style K fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style L fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
```

## Señales de Control

### Señales de Entrada
```mermaid
graph TD
    A[MemRead] --> B[Read Enable]
    C[MemWrite] --> D[Write Enable]
    E[BHW Type] --> F[Data Size Control]
    G[ALU Result] --> H[Memory Address]
    I[Write Data] --> J[Data to Write]
    
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

### Señales de Salida
```mermaid
graph TD
    A[Read Data] --> B[Memory Data to WB]
    C[ALU Result Out] --> D[ALU Result to WB]
    E[RD Out] --> F[Register Address to WB]
    G[MemToReg Out] --> H[Control Signal to WB]
    I[RegWrite Out] --> J[Write Enable to WB]
    
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

## Timing y Latencia

### Timing Diagram
```mermaid
graph LR
    subgraph "Clock Cycle 1"
        A1[Address Setup] --> B1[Memory Access]
    end
    subgraph "Clock Cycle 2"
        A2[Data Ready] --> B2[MEM/WB Latch]
    end
    
    B1 --> A2
    
    style A1 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B1 fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style A2 fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style B2 fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
```

### Latencia de Memoria
- **Acceso a memoria**: 1 ciclo de reloj
- **Operaciones combinacionales**: Sin latencia adicional
- **Total**: 1 ciclo de reloj

## Casos Especiales

### 1. Load-Use Hazard
```mermaid
graph TD
    A[LW R1, 100(R2)] --> B[Load from Memory]
    C[ADD R3, R1, R4] --> D[Use Loaded Value]
    
    B --> E[Stall Required]
    E --> F[Forward from MEM/WB]
    
    style A fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style B fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style C fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style D fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style E fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style F fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
```

### 2. Memory Alignment
```mermaid
graph TD
    A[Unaligned Address] --> B[Address Check]
    B --> C{Aligned?}
    C -->|Yes| D[Normal Access]
    C -->|No| E[Alignment Exception]
    
    D --> F[Memory Operation]
    E --> G[Exception Handler]
    
    style A fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style B fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style C fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style D fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style E fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style F fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
```

### 3. Memory Protection
```mermaid
graph TD
    A[Memory Access] --> B[Address Range Check]
    B --> C{Valid Range?}
    C -->|Yes| D[Memory Operation]
    C -->|No| E[Memory Exception]
    
    D --> F[Success]
    E --> G[Exception Handler]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
```

## Optimizaciones Implementadas

### 1. Memoria Optimizada
- Acceso directo sin latencia adicional
- Soporte para diferentes tamaños de datos
- Alineación automática

### 2. Control de Hazards
- Detección de load-use hazards
- Forwarding desde memoria
- Stall automático cuando es necesario

### 3. Debug Support
- Acceso a memoria para debug
- Monitoreo de operaciones
- Lectura de datos de memoria

## Integración con Debug Unit

La etapa MEM se integra con la debug unit para permitir:
- Lectura de memoria vía UART
- Monitoreo de operaciones de memoria
- Verificación de datos en memoria
- Control de acceso a memoria

## Archivos Relacionados

- `MEM.v`: Módulo principal de la etapa
- `MEMDATA.v`: Memoria de datos
- `EX_MEM.v`: Registro de segmentación de entrada
- `MEM_WB.v`: Registro de segmentación de salida
- `testbenchs/load_store.v`: Testbench de operaciones de memoria
- `testbenchs/store_test.v`: Testbench específico para store 