# Módulos Utilitarios

## Descripción General

Los módulos utilitarios son componentes reutilizables que proporcionan funcionalidades básicas utilizadas en múltiples etapas del pipeline MIPS. Estos módulos incluyen la Unidad Aritmético-Lógica (ALU) y multiplexores genéricos.

## Arquitectura General

```mermaid
graph TD
    A[Utility Modules] --> B[ALU<br/>Arithmetic Logic Unit]
    A --> C[MUX2TO1<br/>2-to-1 Multiplexer]
    A --> D[ALU_CONTROL<br/>ALU Control Unit]
    
    B --> E[Arithmetic Operations]
    B --> F[Logical Operations]
    B --> G[Shift Operations]
    B --> H[Comparison Operations]
    
    C --> I[Data Selection]
    C --> J[Control Selection]
    
    D --> K[Operation Decoding]
    D --> L[Control Signal Generation]
    
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

## Módulos Componentes

### 1. ALU.v - Unidad Aritmético-Lógica

**Descripción**: Módulo central que ejecuta todas las operaciones aritméticas y lógicas del procesador MIPS.

**Funcionalidades**:
- Operaciones aritméticas (ADD, SUB, MULT)
- Operaciones lógicas (AND, OR, XOR, NOR)
- Operaciones de desplazamiento (SLL, SRL, SRA)
- Operaciones de comparación (SLT, SLTU)
- Generación de flags de condición

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

**Diagrama de Arquitectura ALU**:
```mermaid
graph TD
    A[Operand A] --> B[ALU Core]
    C[Operand B] --> B
    D[Operation Code] --> E[Operation Decoder]
    E --> B
    
    B --> F[Result]
    B --> G[Zero Flag]
    
    E --> H[Arithmetic Unit]
    E --> I[Logical Unit]
    E --> J[Shift Unit]
    E --> K[Comparison Unit]
    
    H --> L[ADD/SUB/MULT]
    I --> M[AND/OR/XOR/NOR]
    J --> N[SLL/SRL/SRA]
    K --> O[SLT/SLTU]
    
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

#### Operaciones Aritméticas
```mermaid
graph LR
    A[ADD: 100001] --> B[Addition<br/>A + B]
    C[SUB: 100011] --> D[Subtraction<br/>A - B]
    E[MULT: 011000] --> F[Multiplication<br/>A * B]
    G[MULTU: 011001] --> H[Unsigned Mult<br/>A * B]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
```

#### Operaciones Lógicas
```mermaid
graph LR
    A[AND: 100100] --> B[Logical AND<br/>A & B]
    C[OR: 100101] --> D[Logical OR<br/>A | B]
    E[XOR: 100110] --> F[Logical XOR<br/>A ^ B]
    G[NOR: 100111] --> H[Logical NOR<br/>~(A | B)]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
```

#### Operaciones de Desplazamiento
```mermaid
graph LR
    A[SLL: 000000] --> B[Shift Left Logical<br/>B << A]
    C[SRL: 000010] --> D[Shift Right Logical<br/>B >> A]
    E[SRA: 000011] --> F[Shift Right Arithmetic<br/>B >>> A]
    G[SLLV: 000100] --> H[Shift Left Variable<br/>B << A[4:0]]
    I[SRLV: 000110] --> J[Shift Right Variable<br/>B >> A[4:0]]
    K[SRAV: 000111] --> L[Shift Right Arithmetic Variable<br/>B >>> A[4:0]]
    
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

#### Operaciones de Comparación
```mermaid
graph LR
    A[SLT: 101010] --> B[Set Less Than<br/>A < B ? 1 : 0]
    C[SLTU: 101011] --> D[Set Less Than Unsigned<br/>A < B ? 1 : 0]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
```

### 2. MUX2TO1.v - Multiplexor 2:1

**Descripción**: Multiplexor genérico de 2 entradas y 1 salida con ancho de datos configurable.

**Funcionalidades**:
- Selección entre dos entradas
- Ancho de datos configurable
- Control de selección de 1 bit
- Aplicaciones múltiples en el pipeline

**Interfaces**:
```verilog
module MUX2TO1 #(
    parameter WIDTH = 32
)(
    input wire [WIDTH-1:0] input_1,
    input wire [WIDTH-1:0] input_2,
    input wire selection_bit,
    output reg [WIDTH-1:0] mux
);
```

**Diagrama de Funcionamiento**:
```mermaid
graph LR
    A[Input 1] --> D[MUX2TO1]
    B[Input 2] --> D
    C[Selection Bit] --> D
    D --> E[Selected Output]
    
    C --> F{Selection}
    F -->|0| G[Output = Input 1]
    F -->|1| H[Output = Input 2]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
    style H fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
```

#### Aplicaciones del Multiplexor
```mermaid
graph TD
    A[MUX2TO1 Applications] --> B[ALU Source Selection]
    A --> C[Register Destination Selection]
    A --> D[Memory to Register Selection]
    A --> E[PC Source Selection]
    A --> F[Branch Target Selection]
    
    B --> G[Register vs Immediate]
    C --> H[RT vs RD]
    D --> I[ALU Result vs Memory Data]
    E --> J[PC+4 vs Branch Address]
    F --> K[Sequential vs Branch]
    
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

## Flujo de Datos en Operaciones

### Operación Aritmética Típica
```mermaid
sequenceDiagram
    participant ID as ID Stage
    participant EX as EX Stage
    participant ALU as ALU
    participant WB as WB Stage
    
    ID->>EX: Operands + Operation
    EX->>ALU: Data A, Data B, Op Code
    ALU->>ALU: Execute Operation
    ALU->>EX: Result + Zero Flag
    EX->>WB: ALU Result
    WB->>WB: Write to Register
```

### Operación de Desplazamiento
```mermaid
sequenceDiagram
    participant ID as ID Stage
    participant EX as EX Stage
    participant ALU as ALU
    participant WB as WB Stage
    
    ID->>EX: Source + Shift Amount + Op
    EX->>ALU: Data, Shift Amount, SLL/SRL/SRA
    ALU->>ALU: Perform Shift
    ALU->>EX: Shifted Result
    EX->>WB: Shifted Data
    WB->>WB: Write to Register
```

### Operación de Comparación
```mermaid
sequenceDiagram
    participant ID as ID Stage
    participant EX as EX Stage
    participant ALU as ALU
    participant WB as WB Stage
    
    ID->>EX: Operands + SLT/SLTU
    EX->>ALU: Data A, Data B, Compare Op
    ALU->>ALU: Compare Values
    ALU->>EX: Comparison Result (0/1)
    EX->>WB: Comparison Result
    WB->>WB: Write to Register
```

## Optimizaciones Implementadas

### 1. ALU Optimizada
```mermaid
graph TD
    A[ALU Optimizations] --> B[Combinational Logic]
    A --> C[Parallel Execution]
    A --> D[Efficient Encoding]
    A --> E[Flag Generation]
    
    B --> F[Fast Operation]
    C --> G[Multiple Units]
    D --> H[Compact Control]
    E --> I[Zero Flag]
    
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

### 2. Multiplexor Eficiente
```mermaid
graph TD
    A[MUX Optimizations] --> B[Parameterized Width]
    A --> C[Minimal Logic]
    A --> D[Fast Selection]
    A --> E[Reusable Design]
    
    B --> F[Flexible Usage]
    C --> G[Low Area]
    D --> H[High Speed]
    E --> I[Multiple Applications]
    
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

## Casos de Uso Específicos

### 1. Forwarding con Multiplexores
```mermaid
graph TD
    A[Forwarding Scenario] --> B[Detect Hazard]
    B --> C[Select Forwarded Data]
    C --> D[Use MUX2TO1]
    D --> E[Provide Correct Operand]
    
    F[Original Data] --> G[MUX2TO1]
    H[Forwarded Data] --> G
    I[Forward Signal] --> G
    G --> J[Selected Operand]
    
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

### 2. Control de Hazards
```mermaid
graph TD
    A[Hazard Detection] --> B[Stall Pipeline]
    B --> C[Use MUX2TO1 for Control]
    C --> D[Select Stall vs Normal]
    D --> E[Control Pipeline Flow]
    
    F[Normal Control] --> G[MUX2TO1]
    H[Stall Control] --> G
    I[Stall Signal] --> G
    G --> J[Selected Control]
    
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

## Integración con el Pipeline

### Conexiones con Etapas
```mermaid
graph TD
    A[Utility Modules] --> B[IF Stage<br/>PC Control]
    A --> C[ID Stage<br/>Hazard Detection]
    A --> D[EX Stage<br/>ALU Operations]
    A --> E[MEM Stage<br/>Address Calculation]
    A --> F[WB Stage<br/>Data Selection]
    
    G[ALU] --> H[Execute Operations]
    I[MUX2TO1] --> J[Data Selection]
    K[ALU_CONTROL] --> L[Operation Control]
    
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

## Archivos Relacionados

- `ALU.v`: Unidad Aritmético-Lógica
- `MUX2TO1.v`: Multiplexor 2:1 genérico
- `testbenchs/`: Testbenches para verificación 