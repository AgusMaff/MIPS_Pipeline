# Etapa EX (Execute)

## Descripción General

La etapa EX (Execute) es la tercera etapa del pipeline MIPS. Su función principal es ejecutar las operaciones aritméticas y lógicas, manejar el forwarding de datos para evitar hazards, y preparar los datos para la etapa de memoria.

## Arquitectura del Módulo

```mermaid
graph TD
    A[Data1/Data2<br/>from ID] --> B[FORWARDING_UNIT_EX<br/>Forward Detection]
    B --> C[MUX3TO1<br/>Forward A]
    B --> D[MUX3TO1<br/>Forward B]
    
    C --> E[Operand A<br/>to ALU]
    D --> F[Data2<br/>Write Data]
    F --> G[MUX2TO1<br/>ALU Src]
    
    G -->|0| H[Operand B<br/>Register Value]
    G -->|1| I[Operand B<br/>Immediate]
    
    E --> J[ALU<br/>Execute]
    H --> J
    I --> J
    
    B --> K[ALU_CONTROL<br/>Control Signal]
    K --> J
    
    J --> L[ALU Result]
    F --> M[Write Data<br/>to Memory]
    
    N[RegDest MUX] --> O[Write Register<br/>Address]
    
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
    style N fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    style O fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
```

## Módulos Componentes

### 1. ALU.v - Unidad Aritmético-Lógica

**Descripción**: Ejecuta todas las operaciones aritméticas y lógicas del procesador.

**Operaciones Soportadas**:
- **Aritméticas**: ADD, SUB, MULT, MULTU
- **Lógicas**: AND, OR, XOR, NOR
- **Desplazamientos**: SLL, SRL, SRA, SLLV, SRLV, SRAV
- **Comparaciones**: SLT, SLTU

**Interfaces**:
```verilog
module ALU(
    input wire [31:0] data_a,
    input wire [31:0] data_b,
    input wire [5:0] operation,
    output reg [31:0] result,
    output reg zero_flag
);
```

**Diagrama de Operaciones**:
```mermaid
graph TD
    A[Operand A] --> B[ALU Core]
    C[Operand B] --> B
    D[Operation Code] --> E[Operation Decoder]
    E --> B
    
    B --> F[Result]
    B --> G[Zero Flag]
    
    E --> H[ADD/SUB]
    E --> I[AND/OR/XOR]
    E --> J[Shift Operations]
    E --> K[Compare Operations]
    
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

### 2. ALU_CONTROL.v - Control de la ALU

**Descripción**: Genera las señales de control específicas para la ALU basándose en ALUOp y function code.

**Funcionalidades**:
- Decodificación de ALUOp
- Generación de señales de control específicas
- Soporte para todas las operaciones MIPS

**Interfaces**:
```verilog
module ALU_CONTROL(
    input wire [3:0] alu_op,
    input wire [5:0] function_code,
    output reg [5:0] alu_control
);
```

**Diagrama de Control**:
```mermaid
graph TD
    A[ALUOp] --> B[Control Decoder]
    C[Function Code] --> B
    B --> D[ALU Control Signal]
    
    B --> E[ADD: 100001]
    B --> F[SUB: 100011]
    B --> G[AND: 100100]
    B --> H[OR: 100101]
    B --> I[XOR: 100110]
    B --> J[SLT: 101010]
    B --> K[SLL: 000000]
    B --> L[SRL: 000010]
    B --> M[SRA: 000011]
    
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

### 3. FORWARDING_UNIT_EX.v - Unidad de Forwarding

**Descripción**: Detecta y maneja el forwarding de datos para evitar hazards RAW.

**Funcionalidades**:
- Detección de hazards de datos
- Forwarding desde EX/MEM
- Forwarding desde MEM/WB
- Control de multiplexores de forwarding

**Interfaces**:
```verilog
module FORWARDING_UNIT_EX(
    input wire [4:0] id_ex_rs,
    input wire [4:0] id_ex_rt,
    input wire [4:0] ex_mem_rd,
    input wire [4:0] mem_wb_rd,
    input wire ex_mem_reg_write,
    input wire mem_wb_reg_write,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);
```

**Diagrama de Forwarding**:
```mermaid
graph TD
    A[ID/EX RS] --> B[Forward Detection<br/>Logic]
    C[ID/EX RT] --> B
    D[EX/MEM RD] --> B
    E[MEM/WB RD] --> B
    F[EX/MEM RegWrite] --> B
    G[MEM/WB RegWrite] --> B
    
    B --> H{Forward A<br/>Needed?}
    H -->|Yes| I[Forward A = 10/01]
    H -->|No| J[Forward A = 00]
    
    B --> K{Forward B<br/>Needed?}
    K -->|Yes| L[Forward B = 10/01]
    K -->|No| M[Forward B = 00]
    
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

### 4. MUX3TO1.v - Multiplexor 3:1

**Descripción**: Multiplexor de 3 entradas para selección de operandos con forwarding.

**Funcionalidad**:
- Selección entre valor original, EX/MEM, y MEM/WB
- Control de forwarding de datos

**Interfaces**:
```verilog
module MUX3TO1(
    input wire [31:0] input_1,
    input wire [31:0] input_2,
    input wire [31:0] input_3,
    input wire [1:0] selection_bit,
    output reg [31:0] mux
);
```

**Diagrama de Selección**:
```mermaid
graph LR
    A[Input 1<br/>Original] --> D[MUX3TO1]
    B[Input 2<br/>EX/MEM] --> D
    C[Input 3<br/>MEM/WB] --> D
    E[Selection<br/>00/01/10] --> D
    D --> F[Selected Output]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

### 5. MUX2TO1_EX.v - Multiplexor 2:1

**Descripción**: Multiplexor de 2 entradas para selección de registro destino.

**Funcionalidad**:
- Selección entre RT y RD para registro destino
- Control de RegDest

**Interfaces**:
```verilog
module MUX2TO1_EX(
    input wire [4:0] input_1,
    input wire [4:0] input_2,
    input wire selection_bit,
    output reg [4:0] mux
);
```

## Flujo de Datos Detallado

### Ejecución de Instrucción R-Type
```mermaid
sequenceDiagram
    participant ID as ID Stage
    participant FU as Forwarding Unit
    participant MUX as MUX3TO1
    participant ALU as ALU
    participant AC as ALU Control
    participant EX_MEM as EX/MEM Latch
    
    ID->>FU: RS/RT Addresses
    FU->>MUX: Forward Signals
    MUX->>ALU: Operands
    ID->>AC: ALUOp + Function
    AC->>ALU: Control Signal
    ALU->>EX_MEM: Result
```

### Ejecución de Instrucción I-Type
```mermaid
sequenceDiagram
    participant ID as ID Stage
    participant MUX as ALU Src MUX
    participant ALU as ALU
    participant AC as ALU Control
    participant EX_MEM as EX/MEM Latch
    
    ID->>MUX: Register + Immediate
    MUX->>ALU: Selected Operand
    ID->>AC: ALUOp
    AC->>ALU: Control Signal
    ALU->>EX_MEM: Result
```

### Forwarding de Datos
```mermaid
sequenceDiagram
    participant FU as Forwarding Unit
    participant EX_MEM as EX/MEM
    participant MEM_WB as MEM/WB
    participant MUX as MUX3TO1
    participant ALU as ALU
    
    FU->>FU: Check Dependencies
    FU->>MUX: Forward Control
    EX_MEM->>MUX: Forwarded Data
    MEM_WB->>MUX: Forwarded Data
    MUX->>ALU: Correct Operands
```

## Tipos de Operaciones

### Operaciones Aritméticas
```mermaid
graph LR
    A[ADD] --> B[Addition]
    C[SUB] --> D[Subtraction]
    E[ADDI] --> F[Add Immediate]
    G[ADDIU] --> H[Add Immediate Unsigned]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
```

### Operaciones Lógicas
```mermaid
graph LR
    A[AND] --> B[Logical AND]
    C[OR] --> D[Logical OR]
    E[XOR] --> F[Logical XOR]
    G[NOR] --> H[Logical NOR]
    I[ANDI] --> J[AND Immediate]
    K[ORI] --> L[OR Immediate]
    M[XORI] --> N[XOR Immediate]
    
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
```

### Operaciones de Desplazamiento
```mermaid
graph LR
    A[SLL] --> B[Shift Left Logical]
    C[SRL] --> D[Shift Right Logical]
    E[SRA] --> F[Shift Right Arithmetic]
    G[SLLV] --> H[Shift Left Variable]
    I[SRLV] --> J[Shift Right Variable]
    K[SRAV] --> L[Shift Right Arithmetic Variable]
    
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
```

### Operaciones de Comparación
```mermaid
graph LR
    A[SLT] --> B[Set Less Than]
    C[SLTU] --> D[Set Less Than Unsigned]
    E[SLTI] --> F[Set Less Than Immediate]
    G[SLTIU] --> H[Set Less Than Immediate Unsigned]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
```

## Forwarding y Hazards

### Detección de Forwarding
```mermaid
graph TD
    A[Check RS/RT] --> B{Match EX/MEM RD?}
    B -->|Yes| C[Forward from EX/MEM]
    B -->|No| D{Match MEM/WB RD?}
    D -->|Yes| E[Forward from MEM/WB]
    D -->|No| F[No Forwarding]
    
    C --> G[Forward A/B = 10]
    E --> H[Forward A/B = 01]
    F --> I[Forward A/B = 00]
    
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

### Casos de Forwarding
```mermaid
graph TD
    A[ADD R1, R2, R3] --> B[R3 = R1 + R2]
    C[SUB R4, R3, R5] --> D[R5 = R4 - R3]
    E[AND R6, R5, R7] --> F[R7 = R6 & R5]
    
    B --> G[Forward R3 to SUB]
    D --> H[Forward R5 to AND]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
```

## Timing y Latencia

### Timing Diagram
```mermaid
graph LR
    subgraph "Clock Cycle 1"
        A1[Forward Detection] --> B1[Operand Selection]
    end
    subgraph "Clock Cycle 2"
        A2[ALU Execution] --> B2[Result Generation]
    end
    subgraph "Clock Cycle 3"
        A3[EX/MEM Latch] --> B3[Next Stage]
    end
    
    B1 --> A2
    B2 --> A3
    
    style A1 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B1 fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style A2 fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style B2 fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style A3 fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style B3 fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

## Optimizaciones Implementadas

### 1. Forwarding Optimizado
- Detección temprana de hazards
- Forwarding desde múltiples etapas
- Mínimo overhead de latencia

### 2. ALU Optimizada
- Operaciones combinacionales rápidas
- Soporte para todas las instrucciones MIPS
- Flags de condición eficientes

### 3. Control de Hazards
- Forwarding automático
- Detección de dependencias
- Resolución sin stall

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

### 2. Branch Hazard
```mermaid
graph TD
    A[BEQ R1, R2, Label] --> B[Branch Decision]
    B --> C{Branch Taken?}
    C -->|Yes| D[Flush Pipeline]
    C -->|No| E[Continue Sequential]
    
    style A fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style B fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style C fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style D fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style E fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
```

## Integración con Debug Unit

La etapa EX se integra con la debug unit para permitir:
- Monitoreo de operandos y resultados
- Verificación de forwarding
- Debug de operaciones ALU
- Control de ejecución

## Archivos Relacionados

- `EX.v`: Módulo principal de la etapa
- `ALU.v`: Unidad Aritmético-Lógica
- `ALU_CONTROL.v`: Control de la ALU
- `FORWARDING_UNIT_EX.v`: Unidad de forwarding
- `MUX2TO1_EX.v`: Multiplexor 2:1
- `MUX3TO1.v`: Multiplexor 3:1
- `EX_MEM.v`: Registro de segmentación
- `testbenchs/ex_test.v`: Testbench de la etapa 