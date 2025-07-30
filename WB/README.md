# Etapa WB (Write Back)

## Descripción General

La etapa WB (Write Back) es la quinta y última etapa del pipeline MIPS. Su función principal es escribir los resultados de las operaciones en el banco de registros, completando así el ciclo de ejecución de una instrucción.

## Arquitectura del Módulo

```mermaid
graph TD
    A[ALU Result<br/>from MEM] --> B[MUX2TO1<br/>Mem to Reg]
    C[Memory Data<br/>from MEM] --> B
    
    B -->|0| D[Write Data<br/>ALU Result]
    B -->|1| E[Write Data<br/>Memory Data]
    
    D --> F[REGMEM<br/>Write to Register]
    E --> F
    
    G[Control Signals] --> H[Register Control]
    H --> F
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
```

## Módulos Componentes

### 1. WB.v - Controlador de Write Back

**Descripción**: Módulo principal que controla la escritura de resultados en el banco de registros.

**Funcionalidades**:
- Selección entre resultado de ALU y datos de memoria
- Control de escritura en registros
- Integración con debug unit
- Completación del ciclo de instrucción

**Interfaces**:
```verilog
module WB(
    input wire [31:0] alu_result,
    input wire [31:0] memory_data,
    input wire mem_to_reg,
    input wire reg_write,
    input wire [4:0] rd,
    output wire [31:0] write_data,
    output wire [4:0] write_reg,
    output wire write_enable
);
```

**Diagrama de Control**:
```mermaid
graph TD
    A[ALU Result] --> B[Data Selection]
    C[Memory Data] --> B
    D[MemToReg] --> B
    
    B --> E[Write Data]
    E --> F[Register File]
    
    G[RD] --> H[Write Address]
    I[RegWrite] --> J[Write Enable]
    
    H --> F
    J --> F
    
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

## Tipos de Operaciones

### Operaciones R-Type (ALU)
```mermaid
graph LR
    A[ADD/SUB] --> B[ALU Result]
    C[AND/OR/XOR] --> B
    D[SLL/SRL/SRA] --> B
    E[SLT/SLTU] --> B
    
    B --> F[Write to Register]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

### Operaciones I-Type (Load)
```mermaid
graph LR
    A[LW] --> B[Memory Data]
    C[LH/LB] --> B
    D[LHU/LBU] --> B
    
    B --> E[Write to Register]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
```

### Operaciones I-Type (Immediate)
```mermaid
graph LR
    A[ADDI/ADDIU] --> B[ALU Result]
    C[ANDI/ORI/XORI] --> B
    D[SLTI/SLTIU] --> B
    
    B --> E[Write to Register]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
```

## Flujo de Datos Detallado

### Write Back de Operación ALU
```mermaid
sequenceDiagram
    participant MEM as MEM Stage
    participant WB as Write Back Stage
    participant RF as Register File
    
    MEM->>WB: ALU Result
    MEM->>WB: Control Signals
    WB->>WB: Select ALU Result
    WB->>RF: Write Data + Address
    RF->>RF: Update Register
```

### Write Back de Operación Load
```mermaid
sequenceDiagram
    participant MEM as MEM Stage
    participant WB as Write Back Stage
    participant RF as Register File
    
    MEM->>WB: Memory Data
    MEM->>WB: Control Signals
    WB->>WB: Select Memory Data
    WB->>RF: Write Data + Address
    RF->>RF: Update Register
```

### Write Back de Operación Store
```mermaid
sequenceDiagram
    participant MEM as MEM Stage
    participant WB as Write Back Stage
    
    MEM->>WB: Control Signals
    WB->>WB: No Register Write
    Note over WB: Store operations don't write to registers
```

## Selección de Datos

### Multiplexor MemToReg
```mermaid
graph TD
    A[ALU Result] --> B[MUX2TO1<br/>MemToReg]
    C[Memory Data] --> B
    D[MemToReg Signal] --> B
    
    B -->|0| E[Write ALU Result]
    B -->|1| F[Write Memory Data]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

### Control de Escritura
```mermaid
graph TD
    A[RegWrite Signal] --> B{Write Enable?}
    B -->|Yes| C[Write to Register]
    B -->|No| D[No Write]
    
    C --> E[Update Register File]
    D --> F[Skip Write]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

## Señales de Control

### Señales de Entrada
```mermaid
graph TD
    A[ALU Result] --> B[Data Source 1]
    C[Memory Data] --> D[Data Source 2]
    E[MemToReg] --> F[Data Selection]
    G[RegWrite] --> H[Write Enable]
    I[RD] --> J[Write Address]
    
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
    A[Write Data] --> B[Data to Register]
    C[Write Register] --> D[Register Address]
    D[Write Enable] --> E[Write Control]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
```

## Timing y Latencia

### Timing Diagram
```mermaid
graph LR
    subgraph "Clock Cycle 1"
        A1[Data Selection] --> B1[Register Write]
    end
    subgraph "Clock Cycle 2"
        A2[Register Updated] --> B2[Instruction Complete]
    end
    
    B1 --> A2
    
    style A1 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B1 fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style A2 fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style B2 fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
```

### Latencia de Write Back
- **Selección de datos**: Combinacional
- **Escritura en registro**: 1 ciclo de reloj
- **Total**: 1 ciclo de reloj

## Casos Especiales

### 1. Write to R0
```mermaid
graph TD
    A[Write to R0] --> B[Register Check]
    B --> C{R0?}
    C -->|Yes| D[Ignore Write]
    C -->|No| E[Normal Write]
    
    D --> F[No Effect]
    E --> G[Update Register]
    
    style A fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style B fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style C fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style D fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style E fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style F fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
```

### 2. Multiple Writes
```mermaid
graph TD
    A[Multiple Instructions] --> B[Write Order]
    B --> C[Pipeline Order]
    C --> D[Last Write Wins]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
```

### 3. Forwarding Completion
```mermaid
graph TD
    A[Forwarding Active] --> B[Data Available]
    B --> C[Register Write]
    C --> D[Forwarding Complete]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
```

## Completación de Instrucciones

### Ciclo de Vida de una Instrucción
```mermaid
graph LR
    A[IF] --> B[ID]
    B --> C[EX]
    C --> D[MEM]
    D --> E[WB]
    E --> F[Complete]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

### Estados de Completación
```mermaid
graph TD
    A[Instruction in WB] --> B{Type?}
    B -->|R-Type| C[Write ALU Result]
    B -->|Load| D[Write Memory Data]
    B -->|Store| E[No Write]
    B -->|Branch| F[No Write]
    B -->|Jump| G[No Write]
    
    C --> H[Register Updated]
    D --> H
    E --> I[Memory Updated]
    F --> J[PC Updated]
    G --> J
    
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

## Optimizaciones Implementadas

### 1. Write Back Optimizado
- Selección de datos eficiente
- Control de escritura optimizado
- Integración con forwarding

### 2. Control de Hazards
- Completación de forwarding
- Resolución de dependencias
- Actualización de registros

### 3. Debug Support
- Monitoreo de escrituras
- Verificación de resultados
- Control de completación

## Integración con Debug Unit

La etapa WB se integra con la debug unit para permitir:
- Monitoreo de escrituras en registros
- Verificación de resultados finales
- Control de completación de instrucciones
- Debug de forwarding

## Archivos Relacionados

- `WB.v`: Módulo principal de la etapa
- `MEM_WB.v`: Registro de segmentación de entrada
- `REGMEM.v`: Banco de registros (en etapa ID)
- `testbenchs/`: Testbenches relacionados 