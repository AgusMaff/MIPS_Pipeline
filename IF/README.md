# Etapa IF (Instruction Fetch)

## Descripción General

La etapa IF (Instruction Fetch) es la primera etapa del pipeline MIPS. Su función principal es obtener la siguiente instrucción de la memoria de instrucciones y calcular la dirección de la siguiente instrucción (PC+4).

## Arquitectura del Módulo

```mermaid
graph TD
    A[PC<br/>Program Counter] --> B[INSMEM<br/>Instruction Memory]
    B --> C[Instruction<br/>32-bit]
    
    A --> D[PC+4<br/>ALU]
    D --> E[Next PC<br/>Calculation]
    
    E --> F{MUX BEQ<br/>PCSrc}
    F -->|0| G[PC+4<br/>Normal Flow]
    F -->|1| H[BEQ Address<br/>Branch Target]
    
    G --> I{MUX JMP<br/>Jump}
    H --> I
    I -->|0| J[Next PC<br/>Final]
    I -->|1| K[JMP Address<br/>Jump Target]
    
    K --> L[SHFT2L<br/>Shift Left 2]
    L --> J
    
    J --> A
    
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

### 1. PC.v - Contador de Programa

**Descripción**: Registro que mantiene la dirección de la instrucción actual.

**Funcionalidades**:
- Almacena la dirección de la instrucción actual
- Se actualiza cada ciclo de reloj
- Soporta stall para hazards
- Reset asíncrono

**Interfaces**:
```verilog
module PC(
    input wire clk,
    input wire reset,
    input wire [31:0] next_pc,
    input wire write_en,
    input wire stall,
    output reg [31:0] pc
);
```

**Diagrama de Funcionamiento**:
```mermaid
graph LR
    A[Current PC] --> B{Stall?}
    B -->|Yes| C[Keep Current PC]
    B -->|No| D[Next PC]
    D --> E[Update PC<br/>on Clock Edge]
    E --> A
    
    F[Reset] --> G[PC = 0]
    G --> A
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style C fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style D fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style E fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style F fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
```

### 2. INSMEM.v - Memoria de Instrucciones

**Descripción**: Memoria ROM que almacena las instrucciones del programa.

**Características**:
- Memoria de solo lectura
- Direccionamiento por palabra (32 bits)
- Capacidad configurable
- Soporte para debug unit

**Interfaces**:
```verilog
module INSMEM(
    input wire clk,
    input wire reset,
    input wire write_en,
    input wire read_en,
    input wire [31:0] data,
    input wire [31:0] addr,
    input wire [31:0] addr_wr,
    output reg [31:0] instruction
);
```

**Diagrama de Memoria**:
```mermaid
graph TD
    A[PC Address] --> B[Address Decoder]
    B --> C[Instruction Memory<br/>Array]
    C --> D[Instruction<br/>Output]
    
    E[Debug Write] --> F[Write Enable]
    F --> G[Write Data]
    G --> C
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
    style G fill:#fff8e1,stroke:#f57c00,stroke-width:2px,color:#000
```

### 3. SHFT2L.v - Desplazamiento para Saltos

**Descripción**: Módulo que realiza el desplazamiento a la izquierda de 2 bits para instrucciones de salto.

**Funcionalidad**:
- Toma los 26 bits de dirección de salto
- Los desplaza 2 posiciones a la izquierda
- Concatena con los 4 bits superiores del PC

**Interfaces**:
```verilog
module SHFT2L(
    input wire [3:0] pc_plus_4,
    input wire [25:0] shift,
    output wire [31:0] jump_dir
);
```

**Diagrama de Desplazamiento**:
```mermaid
graph LR
    A[PC+4[31:28]] --> C[Concat]
    B[Instruction[25:0]] --> D[Shift Left 2]
    D --> E[26 bits shifted]
    C --> F[Jump Address<br/>32 bits]
    E --> C
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style C fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style D fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style E fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style F fill:#f1f8e9,stroke:#388e3c,stroke-width:2px,color:#000
```

## Flujo de Datos Detallado

### Ciclo Normal (Sin Saltos)
```mermaid
sequenceDiagram
    participant PC as Program Counter
    participant IM as Instruction Memory
    participant ALU as PC+4 ALU
    participant IF_ID as IF/ID Latch
    
    PC->>IM: Current Address
    IM->>IF_ID: Instruction
    PC->>ALU: Current Address
    ALU->>PC: PC+4
    PC->>IF_ID: PC+4
```

### Ciclo con Salto Condicional (BEQ)
```mermaid
sequenceDiagram
    participant PC as Program Counter
    participant IM as Instruction Memory
    participant MUX as Branch MUX
    participant ID as ID Stage
    
    PC->>IM: Current Address
    IM->>ID: BEQ Instruction
    ID->>MUX: Branch Target
    MUX->>PC: Branch Address
```

### Ciclo con Salto Incondicional (JMP)
```mermaid
sequenceDiagram
    participant PC as Program Counter
    participant IM as Instruction Memory
    participant SHFT as Shift Left 2
    participant MUX as Jump MUX
    
    PC->>IM: Current Address
    IM->>SHFT: Jump Target
    SHFT->>MUX: Shifted Address
    MUX->>PC: Jump Address
```

## Señales de Control

### Entradas
- `i_clk`: Reloj del sistema
- `i_reset`: Señal de reset asíncrono
- `i_stall`: Señal de stall para hazards
- `i_pcsrc`: Selección de dirección (PC+4 o BEQ)
- `i_jump`: Señal de salto incondicional
- `i_beq_dir`: Dirección de salto para BEQ

### Salidas
- `o_pc_plus_4`: PC + 4
- `o_instruction`: Instrucción leída de memoria

## Timing y Latencia

### Timing Diagram
```mermaid
graph LR
    subgraph "Clock Cycle 1"
        A1[PC Update] --> B1[Memory Access]
    end
    subgraph "Clock Cycle 2"
        A2[Instruction Ready] --> B2[IF/ID Latch]
    end
    
    B1 --> A2
    
    style A1 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style B1 fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style A2 fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style B2 fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
```

### Latencia
- **Acceso a memoria**: 1 ciclo de reloj
- **Cálculo PC+4**: Combinacional
- **Desplazamiento**: Combinacional
- **Total**: 1 ciclo de reloj

## Casos Especiales

### 1. Hazard de Control (Stall)
```mermaid
graph TD
    A[Detect Branch] --> B[Stall IF Stage]
    B --> C[Keep Current PC]
    C --> D[Wait for ID Stage]
    D --> E[Resolve Branch]
    E --> F[Continue or Flush]
    
    style A fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style B fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style C fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style D fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style E fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    style F fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
```

### 2. Flush del Pipeline
```mermaid
graph TD
    A[Branch Taken] --> B[Flush IF/ID]
    B --> C[Clear Instruction]
    C --> D[Update PC]
    D --> E[Fetch New Instruction]
    
    style A fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    style B fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    style C fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    style D fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    style E fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
```

## Optimizaciones Implementadas

### 1. Predicción de Saltos
- Predicción estática: "not taken"
- Flush cuando predicción es incorrecta

### 2. Memoria de Instrucciones Optimizada
- Acceso directo sin latencia adicional
- Soporte para debug unit

### 3. Control de Hazards
- Stall automático para hazards de control
- Flush para saltos tomados

## Testbench y Verificación

### Casos de Prueba
1. **Secuencia normal**: PC incrementa secuencialmente
2. **Salto condicional**: BEQ con condición verdadera
3. **Salto incondicional**: JMP a dirección específica
4. **Stall**: Verificación de stall por hazard
5. **Reset**: Comportamiento después de reset

### Métricas de Rendimiento
- **Throughput**: 1 instrucción por ciclo (sin hazards)
- **Latencia**: 1 ciclo de reloj
- **Overhead de stall**: Mínimo

## Integración con Debug Unit

La etapa IF se integra con la debug unit para permitir:
- Carga de instrucciones vía UART
- Monitoreo del PC actual
- Control de ejecución (run/stop)
- Lectura de instrucciones en memoria

## Archivos Relacionados

- `IF.v`: Módulo principal de la etapa
- `PC.v`: Contador de programa
- `INSMEM.v`: Memoria de instrucciones
- `SHFT2L.v`: Desplazamiento para saltos
- `IF_ID.v`: Registro de segmentación
- `testbenchs/if_test.v`: Testbench de la etapa 