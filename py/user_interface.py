import serial
import time

SERIAL_PORT          = '/dev/ttyUSB1'
BAUD_RATE            = 19200
BYTESIZE             = serial.EIGHTBITS
STOPBITS             = serial.STOPBITS_ONE
PARITY               = serial.PARITY_NONE
LOAD_INSTRUCTION_CMD = 0x02
RUN_CMD              = 0x05
RESET_CMD            = 0x0F
READ_REG_CMD         = 0x06
READ_MEM_CMD         = 0x07
READ_LATCH_CMD       = 0x08  
READ_IFID_LATCH_CMD  = 0x09  
READ_IDEX_LATCH_CMD  = 0x0A  
READ_EXM_LATCH_CMD   = 0x0B  
READ_MWB_LATCH_CMD   = 0x0C  
STEP_CMD             = 0x0D

OPCODES = {
    "ADD": 0x00, "SUB": 0x00, "AND": 0x00, "OR": 0x00, "XOR": 0x00, "NOR": 0x00, "SLT": 0x00,
    "ADDU": 0x00, "SUBU": 0x00, "SLTU": 0x00, "SLL": 0x00, "SRL": 0x00, "SRA": 0x00,
    "SLLV": 0x00, "SRLV": 0x00, "SRAV": 0x00,
    "LW": 0x23, "SW": 0x2B, "LB": 0x20, "LH": 0x21, "LWU": 0x27, "LBU": 0x24, "LHU": 0x25,
    "SH": 0x29, "SB": 0x28, "ADDI": 0x09, "ADDIU": 0x09, "ANDI": 0x0C, "ORI": 0x0D, "XORI": 0x0E,
    "LUI": 0x0F, "SLTI": 0x0A, "SLTIU": 0x0B, "BEQ": 0x04, "BNE": 0x05, "HALT": 0x3F
}

FUNCTION_CODES = {
    "ADD": 0x20, "SUB": 0x22, "AND": 0x24, "OR": 0x25, "XOR": 0x26, "NOR": 0x27, "SLT": 0x2A,
    "ADDU": 0x21, "SUBU": 0x23, "SLTU": 0x2B, "SLL": 0x00, "SRL": 0x02, "SRA": 0x03,
    "SLLV": 0x04, "SRLV": 0x06, "SRAV": 0x07
}

REGS = {
    "$zero": 0, "$at": 1, "$v0": 2, "$v1": 3, "$a0": 4, "$a1": 5, "$a2": 6, "$a3": 7,
    "$t0": 8, "$t1": 9, "$t2": 10, "$t3": 11, "$t4": 12, "$t5": 13, "$t6": 14, "$t7": 15,
    "$s0": 16, "$s1": 17, "$s2": 18, "$s3": 19, "$s4": 20, "$s5": 21, "$s6": 22, "$s7": 23,
    "$t8": 24, "$t9": 25, "$k0": 26, "$k1": 27, "$gp": 28, "$sp": 29, "$fp": 30, "$ra": 31
}

def parse_instruction(instr_str):
    """Parses instruction of the form 'ADD $t0 $t1 $t2' and returns mnemonic and operands."""
    parts = instr_str.replace(',', '').split()
    mnemonic = parts[0].upper()
    operands = [op for op in parts[1:]]
    return mnemonic, operands

def encode_instruction(mnemonic, operands):
    """Returns the 32-bit integer encoding of the instruction."""
    opcode = OPCODES.get(mnemonic)
    if opcode is None:
        raise ValueError(f"Instrucción no soportada: {mnemonic}")

    # Tipo R
    if opcode == 0x00:
        funct = FUNCTION_CODES[mnemonic]
        rs = REGS[operands[0]]
        rt = REGS[operands[1]]
        rd = REGS[operands[2]]
        sa = 0

        instr = (opcode << 26) | (rs << 21) | (rt << 16) | (rd << 11) | (sa << 6) | funct
        return instr

    # Tipo I
    elif mnemonic in ["LW", "SW", "LB", "LH", "LWU", "LBU", "LHU", "SB", "SH"]:
        # Formato: OP rt, offset(base)
        # Ejemplo: LW $t0, 4($t1)
        rt = REGS[operands[0]]
        offset, base = operands[1].replace(')', '').split('(')
        base = REGS[base]
        imm = int(offset, 0) & 0xFFFF
        instr = (opcode << 26) | (base << 21) | (rt << 16) | imm
        return instr
    elif mnemonic in ["BEQ", "BNE"]:
        # BEQ rs, rt, offset
        rs = REGS[operands[0]]
        rt = REGS[operands[1]]
        imm = int(operands[2], 0) & 0xFFFF
        instr = (opcode << 26) | (rs << 21) | (rt << 16) | imm
        return instr
    elif mnemonic in ["ADDI", "ADDIU", "ANDI", "ORI", "XORI", "SLTI", "SLTIU"]:
        # ADDI rs, rt, imm
        rs = REGS[operands[0]]
        rt = REGS[operands[1]]
        imm = int(operands[2], 0) & 0xFFFF
        instr = (opcode << 26) | (rs << 21) | (rt << 16) | imm
        return instr
    elif mnemonic == "LUI":
        # LUI rt, imm
        rt = REGS[operands[0]]
        imm = int(operands[1], 0) & 0xFFFF
        instr = (opcode << 26) | (0 << 21) | (rt << 16) | imm
        return instr
    else:
        raise ValueError(f"Formato de instrucción no soportado: {mnemonic}")

def clear_serial_buffers(ser):
    """Limpia los buffers de RX y TX"""
    print("Limpiando buffers UART...")
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    # Leer cualquier dato pendiente
    while ser.in_waiting:
        discarded = ser.read(ser.in_waiting)
        print(f"Descartados {len(discarded)} bytes del buffer RX.")
        time.sleep(0.1)

def receive_bytes(ser, num_bytes, description="datos"):
    """Recibe una cantidad específica de bytes con timeout"""
    print(f"Recibiendo {num_bytes} bytes de {description}...")
    data = b''
    bytes_received = 0
    
    while bytes_received < num_bytes:
        remaining = num_bytes - bytes_received
        chunk = ser.read(remaining)
        
        if len(chunk) == 0:
            print(f"TIMEOUT: Solo se recibieron {bytes_received}/{num_bytes} bytes")
            break
            
        data += chunk
        bytes_received += len(chunk)
        print(f"Recibidos {bytes_received}/{num_bytes} bytes...")
    
    if len(data) < num_bytes:
        print(f"Error: datos incompletos de {description}")
        return None
    
    return data

def send_command(ser, cmd):
    """Envía un comando SIN esperar ACK"""
    print(f"Enviando comando: 0x{cmd:02X}")
    ser.write(bytes([cmd]))
    ser.flush()

def send_instruction(ser, instruction):
    """Envía una instrucción de 32 bits (4 bytes) SIN esperar ACK"""
    instr_bytes = instruction.to_bytes(4, 'big')
    print("Enviando instrucción (bytes):", [f"0x{b:02X}" for b in instr_bytes])
    
    # Enviar todos los bytes sin esperar ACK
    for b in instr_bytes:
        print(f"Enviando byte: 0x{b:02X}")
        ser.write(bytes([b]))
        ser.flush()  # Forzar envío inmediato
    
    print("Instrucción enviada completamente.")

def read_single_register(ser, reg_name):
    """Lee un registro específico usando READ_REG_CMD"""
    # Verificar que el registro existe
    if reg_name not in REGS:
        print(f"Error: Registro '{reg_name}' no válido")
        print("Registros válidos:", list(REGS.keys()))
        return None
    
    reg_num = REGS[reg_name]
    print(f"Leyendo registro {reg_name} (número {reg_num})...")
    
    # Limpiar buffers antes de la operación
    clear_serial_buffers(ser)
    
    # Enviar comando READ_REG SIN esperar ACK
    send_command(ser, READ_REG_CMD)
    print("Comando READ_REG enviado.")
    time.sleep(0.1)
    
    # Enviar número de registro como byte SIN esperar ACK
    print(f"Enviando número de registro: {reg_num} (0x{reg_num:02X})")
    ser.write(bytes([reg_num]))
    ser.flush()
    print("Dirección de registro enviada.")
    
    # Dar tiempo para que la FPGA procese
    time.sleep(0.1)
    
    # Recibir 4 bytes del valor del registro
    reg_data = receive_bytes(ser, 4, f"registro {reg_name}")
    if reg_data is None:
        return None
    
    # Convertir a valor de 32 bits (big endian)
    reg_value = int.from_bytes(reg_data, 'big')
    
    print(f"\n=== RESULTADO ===")
    print(f"Registro {reg_name}: 0x{reg_value:08X} ({reg_value})")
    print(f"Bytes recibidos: {[f'0x{b:02X}' for b in reg_data]}")
    
    return reg_value

def read_memory_address(ser, mem_addr):
    """Lee una dirección de memoria específica usando READ_MEM_CMD"""
    # Verificar que la dirección sea múltiplo de 4
    if mem_addr % 4 != 0:
        print(f"Error: La dirección {mem_addr} no es múltiplo de 4")
        return None
    
    # Verificar que la dirección esté en el rango válido (0-252)
    if mem_addr < 0 or mem_addr > 252:
        print(f"Error: La dirección {mem_addr} está fuera del rango válido (0-252)")
        return None
    
    print(f"Leyendo dirección de memoria: {mem_addr} (0x{mem_addr:02X})...")
    
    # Limpiar buffers antes de la operación
    clear_serial_buffers(ser)
    
    # Enviar comando READ_MEM SIN esperar ACK
    send_command(ser, READ_MEM_CMD)
    print("Comando READ_MEM enviado.")
    time.sleep(0.1)
    
    # Enviar dirección de memoria como 1 byte (8 bits) SIN esperar ACK
    mem_addr_byte = mem_addr & 0xFF  # Asegurar que sea solo 8 bits
    print(f"Enviando dirección: {mem_addr} como byte 0x{mem_addr_byte:02X}")
    ser.write(bytes([mem_addr_byte]))
    ser.flush()
    print("Dirección de memoria enviada.")
    
    # Dar tiempo para que la FPGA procese
    time.sleep(0.1)
    
    # Recibir 4 bytes del valor de memoria
    mem_data = receive_bytes(ser, 4, f"memoria dirección {mem_addr}")
    if mem_data is None:
        return None
    
    # Convertir a valor de 32 bits (big endian)
    mem_value = int.from_bytes(mem_data, 'big')
    
    print(f"\n=== RESULTADO ===")
    print(f"Memoria[{mem_addr}]: 0x{mem_value:08X} ({mem_value})")
    print(f"Bytes recibidos: {[f'0x{b:02X}' for b in mem_data]}")
    
    return mem_value

def read_single_latch(ser, latch_number, latch_name, expected_bytes):
    """Lee un latch específico usando READ_LATCH_CMD + número de latch"""
    print(f"Leyendo latch {latch_name} (número {latch_number})...")
    
    # Limpiar buffers antes de la operación
    clear_serial_buffers(ser)
    
    # Enviar comando READ_LATCH SIN esperar ACK
    send_command(ser, READ_LATCH_CMD)
    print("Comando READ_LATCH enviado.")
    time.sleep(0.5)
    
    # Enviar número de latch como byte SIN esperar ACK
    latch_num = int(latch_number) # Convertir "1"-"4" a 0-3
    print(f"Enviando número de latch: {latch_num} (0x{latch_num:02X})")
    ser.write(bytes([latch_num]))
    ser.flush()
    print("Número de latch enviado.")
    
    # Dar tiempo para que la FPGA procese
    time.sleep(0.5)
    
    # Recibir bytes esperados
    latch_data = receive_bytes(ser, expected_bytes, f"{latch_name} completo")
    if latch_data is None:
        print(f"Error: No se pudieron recibir los datos del latch {latch_name}")
        return None
    
    print(f"Latch {latch_name} recibido exitosamente ({len(latch_data)} bytes)")
    print(f"Datos RAW: {[f'0x{b:02X}' for b in latch_data[:16]]}{'...' if len(latch_data) > 16 else ''}")
    
    return latch_data

def decode_if_id_latch(data):
    """Decodifica el latch IF/ID"""
    if len(data) < 8:
        print(f"Error: Datos insuficientes para IF/ID. Recibidos: {len(data)} bytes, esperados: 8")
        return None
    
    pc_plus_4 = int.from_bytes(data[0:4], 'big')
    instruction = int.from_bytes(data[4:8], 'big')
    
    return {
        'pc_plus_4': pc_plus_4,
        'instruction': instruction
    }

def decode_id_ex_latch_packed(data):
    """Decodifica el latch ID/EX con empaquetado real según debug_unit.v"""
    if len(data) < 17:
        print(f"Error: Datos insuficientes para ID/EX. Recibidos: {len(data)} bytes, esperados: 17")
        return None
    
    # Convertir a entero grande (big endian) - 17 bytes = 136 bits
    packed_data = int.from_bytes(data, 'big')
    
    # ✅ EXTRAER CAMPOS según el empaquetado real del debug_unit.v:
    # assign idex_latch_data = {i_id_ex_data_1,        // 32 bits [135:104]
    #                           i_id_ex_data_2,        // 32 bits [103:72]  
    #                           i_id_ex_rs,            // 5 bits  [71:67]
    #                           i_id_ex_rt,            // 5 bits  [66:62]
    #                           i_id_ex_rd,            // 5 bits  [61:57]
    #                           i_id_ex_function_code, // 6 bits  [56:51]
    #                           i_id_ex_extended_beq_offset, // 32 bits [50:19]
    #                           i_id_ex_reg_dest,      // 1 bit   [18:18]
    #                           i_id_ex_mem_read,      // 1 bit   [17:17]
    #                           i_id_ex_mem_write,     // 1 bit   [16:16]
    #                           i_id_ex_reg_write,     // 1 bit   [15:15]
    #                           i_id_ex_alu_src,       // 1 bit   [14:14]
    #                           i_id_ex_mem_to_reg,    // 1 bit   [13:13]
    #                           i_id_ex_alu_op,        // 4 bits  [12:9]
    #                           i_id_ex_bhw_type,      // 3 bits  [8:6]
    #                           6'b0};                 // 6 bits  [5:0] padding
    
    data_1 = (packed_data >> 104) & 0xFFFFFFFF        # bits 135:104 (32 bits)
    data_2 = (packed_data >> 72) & 0xFFFFFFFF         # bits 103:72  (32 bits)
    rs = (packed_data >> 67) & 0x1F                   # bits 71:67   (5 bits)
    rt = (packed_data >> 62) & 0x1F                   # bits 66:62   (5 bits)
    rd = (packed_data >> 57) & 0x1F                   # bits 61:57   (5 bits)
    function_code = (packed_data >> 51) & 0x3F        # bits 56:51   (6 bits)
    beq_offset = (packed_data >> 19) & 0xFFFFFFFF     # bits 50:19   (32 bits)
    reg_dest = (packed_data >> 18) & 0x1              # bit  18      (1 bit)
    mem_read = (packed_data >> 17) & 0x1              # bit  17      (1 bit)
    mem_write = (packed_data >> 16) & 0x1             # bit  16      (1 bit)
    reg_write = (packed_data >> 15) & 0x1             # bit  15      (1 bit)
    alu_src = (packed_data >> 14) & 0x1               # bit  14      (1 bit)
    mem_to_reg = (packed_data >> 13) & 0x1            # bit  13      (1 bit)
    alu_op = (packed_data >> 9) & 0xF                 # bits 12:9    (4 bits)
    bhw_type = (packed_data >> 6) & 0x7               # bits 8:6     (3 bits)
    padding = packed_data & 0x3F                      # bits 5:0     (6 bits) - solo para debug
    
    return {
        'data_1': data_1,
        'data_2': data_2,
        'rs': rs,
        'rt': rt,
        'rd': rd,
        'function_code': function_code,
        'beq_offset': beq_offset,
        'reg_dest': reg_dest,
        'mem_read': mem_read,
        'mem_write': mem_write,
        'reg_write': reg_write,
        'alu_src': alu_src,
        'mem_to_reg': mem_to_reg,
        'alu_op': alu_op,
        'bhw_type': bhw_type,
        'padding': padding  # Para debug - debería ser 0
    }

def decode_ex_m_latch_packed(data):
    """Decodifica el latch EX/M con empaquetado real según debug_unit.v"""
    if len(data) < 10:
        print(f"Error: Datos insuficientes para EX/M. Recibidos: {len(data)} bytes, esperados: 10")
        return None
    
    # Convertir a entero grande (big endian) - 10 bytes = 80 bits
    packed_data = int.from_bytes(data, 'big')
    
    # ✅ EXTRAER CAMPOS según el empaquetado real del debug_unit.v:
    # assign exm_latch_data = {i_ex_m_rd,           // 5 bits  [79:75]
    #                          i_ex_m_alu_result,   // 32 bits [74:43]
    #                          i_ex_m_write_data,   // 32 bits [42:11]
    #                          i_ex_m_mem_read,     // 1 bit   [10:10]
    #                          i_ex_m_mem_write,    // 1 bit   [9:9]
    #                          i_ex_m_reg_write,    // 1 bit   [8:8]
    #                          i_ex_m_mem_to_reg,   // 1 bit   [7:7]
    #                          i_ex_m_bhw_type,     // 3 bits  [6:4]
    #                          4'b0};               // 4 bits  [3:0] padding
    
    rd = (packed_data >> 75) & 0x1F                   # bits 79:75   (5 bits)
    alu_result = (packed_data >> 43) & 0xFFFFFFFF     # bits 74:43   (32 bits)
    write_data = (packed_data >> 11) & 0xFFFFFFFF     # bits 42:11   (32 bits)
    mem_read = (packed_data >> 10) & 0x1              # bit  10      (1 bit)
    mem_write = (packed_data >> 9) & 0x1              # bit  9       (1 bit)
    reg_write = (packed_data >> 8) & 0x1              # bit  8       (1 bit)
    mem_to_reg = (packed_data >> 7) & 0x1             # bit  7       (1 bit)
    bhw_type = (packed_data >> 4) & 0x7               # bits 6:4     (3 bits)
    padding = packed_data & 0xF                       # bits 3:0     (4 bits) - solo para debug
    
    return {
        'write_reg': rd,
        'alu_result': alu_result,
        'write_data': write_data,
        'mem_read': mem_read,
        'mem_write': mem_write,
        'reg_write': reg_write,
        'mem_to_reg': mem_to_reg,
        'bhw_type': bhw_type,
        'padding': padding  # Para debug - debería ser 0
    }

def decode_m_wb_latch_packed(data):
    """Decodifica el latch M/WB con empaquetado real según debug_unit.v"""
    if len(data) < 9:
        print(f"Error: Datos insuficientes para M/WB. Recibidos: {len(data)} bytes, esperados: 9")
        return None
    
    # Convertir a entero grande (big endian) - 9 bytes = 72 bits
    packed_data = int.from_bytes(data, 'big')
    
    # ✅ EXTRAER CAMPOS según el empaquetado real del debug_unit.v:
    # assign mwb_latch_data = {i_m_wb_rd,           // 5 bits  [71:67]
    #                          i_m_wb_alu_result,   // 32 bits [66:35]
    #                          i_m_wb_read_data,    // 32 bits [34:3]
    #                          i_m_wb_reg_write,    // 1 bit   [2:2]
    #                          2'b0};               // 2 bits  [1:0] padding
    
    rd = (packed_data >> 67) & 0x1F                   # bits 71:67   (5 bits)
    alu_result = (packed_data >> 35) & 0xFFFFFFFF     # bits 66:35   (32 bits)
    read_data = (packed_data >> 3) & 0xFFFFFFFF       # bits 34:3    (32 bits)
    reg_write = (packed_data >> 2) & 0x1              # bit  2       (1 bit)
    padding = packed_data & 0x3                       # bits 1:0     (2 bits) - solo para debug
    
    return {
        'rd': rd,
        'alu_result': alu_result,
        'read_data': read_data,
        'reg_write': reg_write,
        'padding': padding  # Para debug - debería ser 0
    }

def display_latches(latches):
    """Muestra los latches de manera organizada con valores RAW"""
    print("\n" + "="*70)
    print("=== CONTENIDO DE LOS LATCHES DEL PIPELINE ===")
    print("="*70)
    
    # IF/ID
    if 'if_id' in latches:
        if_id = latches['if_id']
        print(f"\nREGISTRO IF/ID:")
        print(f"  PC+4: 0x{if_id['pc_plus_4']:08X} ({if_id['pc_plus_4']})")
        print(f"  Instruction: 0x{if_id['instruction']:08X}")
        if 'if_id_raw' in latches:
            print(f"  RAW Bytes: {[f'0x{b:02X}' for b in latches['if_id_raw']]}")
    
    # ID/EX
    if 'id_ex' in latches:
        id_ex = latches['id_ex']
        print(f"\nREGISTRO ID/EX:")
        print(f"  Data 1: 0x{id_ex['data_1']:08X}")
        print(f"  Data 2: 0x{id_ex['data_2']:08X}")
        print(f"  RS: {id_ex['rs']}, RT: {id_ex['rt']}, RD: {id_ex['rd']}")
        print(f"  BEQ Offset: 0x{id_ex['beq_offset']:08X}")
        print(f"  Function Code: 0x{id_ex['function_code']:02X}")
        print(f"  Control Signals:")
        print(f"    REG DEST: {id_ex['reg_dest']}, ALU SRC: {id_ex['alu_src']}")  # ✅ CORREGIDO
        print(f"    ALU OP: {id_ex['alu_op']}, MEM Read: {id_ex['mem_read']}")
        print(f"    MEM Write: {id_ex['mem_write']}, REG Write: {id_ex['reg_write']}")
        print(f"    MEM to REG: {id_ex['mem_to_reg']}, BHW Type: {id_ex['bhw_type']}")
        print(f"    Padding (debug): 0x{id_ex['padding']:02X}")  # ✅ AGREGAR para debug
        if 'id_ex_raw' in latches:
            print(f"  RAW Bytes: {[f'0x{b:02X}' for b in latches['id_ex_raw']]}")
    
    # EX/M  
    if 'ex_m' in latches:
        ex_m = latches['ex_m']
        print(f"\nREGISTRO EX/M:")
        print(f"  Write REG (RD): {ex_m['write_reg']}")  # ✅ CORREGIDO
        print(f"  ALU Result: 0x{ex_m['alu_result']:08X}")
        print(f"  Write Data: 0x{ex_m['write_data']:08X}")
        print(f"  Control Signals:")
        print(f"    MEM Read: {ex_m['mem_read']}, MEM Write: {ex_m['mem_write']}")
        print(f"    REG Write: {ex_m['reg_write']}, MEM to REG: {ex_m['mem_to_reg']}")
        print(f"    BHW Type: {ex_m['bhw_type']}")
        print(f"    Padding (debug): 0x{ex_m['padding']:01X}")  # ✅ AGREGAR para debug
        if 'ex_m_raw' in latches:
            print(f"  RAW Bytes: {[f'0x{b:02X}' for b in latches['ex_m_raw']]}")
    
    # M/WB
    if 'm_wb' in latches:
        m_wb = latches['m_wb']
        print(f"\nREGISTRO M/WB:")
        print(f"  RD: {m_wb['rd']}")
        print(f"  ALU Result: 0x{m_wb['alu_result']:08X}")
        print(f"  Read Data: 0x{m_wb['read_data']:08X}")
        print(f"  REG Write: {m_wb['reg_write']}")
        print(f"  Padding (debug): 0x{m_wb['padding']:01X}")  # ✅ AGREGAR para debug
        if 'm_wb_raw' in latches:
            print(f"  RAW Bytes: {[f'0x{b:02X}' for b in latches['m_wb_raw']]}")
    
    print("\n" + "="*70)


def main():
    try:
        ser = serial.Serial(
            port=SERIAL_PORT,
            baudrate=BAUD_RATE,
            bytesize=BYTESIZE,
            stopbits=STOPBITS,
            parity=PARITY,
            timeout=1  # Timeout de 1 segundo
        )
    except Exception as e:
        print(f"Error al abrir el puerto serial: {e}")
        return
    
    print("Puerto serie {} abierto a {} bauds.".format(SERIAL_PORT, BAUD_RATE))
    
    # Limpiar buffers al inicio
    clear_serial_buffers(ser)

    while True:
        print("\n=== MENÚ PRINCIPAL ===")
        accion = input("¿Qué desea hacer? (1: Cargar instrucciones, 2: Ejecutar programa, 3: Leer registro, 4: Leer memoria, 5: Leer latch, 6: Avanzar un paso, 7: Reiniciar, 8: Salir): ")

        if accion == "1":
            # Limpiar buffers antes de cargar instrucciones
            clear_serial_buffers(ser)
            
            # Enviar comando LOAD_INSTRUCTION SIN esperar ACK
            send_command(ser, LOAD_INSTRUCTION_CMD)
            print("Comando LOAD_INSTRUCTION enviado.")
            
            while True:
                instr_str = input("Ingrese instrucción (ej: ADD $v0 $v1 $a0, HALT para terminar): ")
                if instr_str.strip().upper() == "HALT":
                    try:
                        send_instruction(ser, (0x3F << 26) | (0 << 21) | (0 << 16) | 0)
                        print("HALT enviado.")
                        break
                    except Exception as e:
                        print(f"Error enviando HALT: {e}")
                        break
                try:
                    mnemonic, operands = parse_instruction(instr_str)
                    instr_bin = encode_instruction(mnemonic, operands)
                    print(f"Instrucción binaria: {instr_bin:032b}")
                    send_instruction(ser, instr_bin)
                except Exception as e:
                    print("Error:", e)
                    
        elif accion == "2":
            # Limpiar buffers antes de ejecutar
            clear_serial_buffers(ser)
            
            # Enviar comando RUN SIN esperar ACK
            send_command(ser, RUN_CMD)
            print("Comando RUN enviado.")
            print("El programa MIPS está ejecutándose...")
            print("Cuando termine la ejecución, use la opción 3 para leer registros individuales.")
                
        elif accion == "3":
            # Leer registro específico
            print("\n=== LEER REGISTRO ESPECÍFICO ===")
            print("Registros disponibles:")
            reg_names = list(REGS.keys())
            for i, reg in enumerate(reg_names):
                print(f"{reg:>6}", end="")
                if (i + 1) % 8 == 0:  # 8 registros por línea
                    print()
            print()  # Nueva línea final
            
            reg_name = input("Ingrese el nombre del registro (ej: $v0, $t1, etc.): ").strip()
            
            # Agregar $ si no lo tiene
            if not reg_name.startswith('$'):
                reg_name = '$' + reg_name
            
            try:
                read_single_register(ser, reg_name)
            except Exception as e:
                print(f"Error leyendo registro: {e}")
                clear_serial_buffers(ser)

        elif accion == "4":
            # Leer memoria específica
            print("\n=== LEER MEMORIA DE DATOS ===")
            print("Direcciones válidas desde 0 hasta 252 (múltiplos de 4)")
            
            addr_str = input("Ingrese dirección de memoria (decimal o 0xHEX): ").strip()
            
            try:
                # Permitir entrada en decimal o hexadecimal
                if addr_str.startswith('0x') or addr_str.startswith('0X'):
                    mem_addr = int(addr_str, 16)
                else:
                    mem_addr = int(addr_str)
                
                read_memory_address(ser, mem_addr)
            except ValueError:
                print("Error: Ingrese un número válido (decimal o 0xHEX)")
            except Exception as e:
                print(f"Error leyendo memoria: {e}")
                clear_serial_buffers(ser)
        
        elif accion == "5":
            print("\n=== LEER LATCH ESPECÍFICO ===")
            print("1: IF/ID (8 bytes)")
            print("2: ID/EX (17 bytes)")   
            print("3: EX/M (10 bytes)")      
            print("4: M/WB (9 bytes)")     

            latch_choice = input("Seleccione latch (1-4): ")

            try:
                if latch_choice == "1":
                    # IF/ID: usar el número de latch directamente
                    data = read_single_latch(ser, READ_IFID_LATCH_CMD, "IF/ID", 8)
                    if data:
                        decoded = decode_if_id_latch(data)
                        if decoded:
                            latches = {'if_id': decoded, 'if_id_raw': data}
                            display_latches(latches)
                elif latch_choice == "2":
                    data = read_single_latch(ser, READ_IDEX_LATCH_CMD, "ID/EX", 17)  
                    if data:
                        decoded = decode_id_ex_latch_packed(data)  # ✅ NUEVA función
                        if decoded:
                            latches = {'id_ex': decoded, 'id_ex_raw': data}
                            display_latches(latches)
                elif latch_choice == "3":
                    data = read_single_latch(ser, READ_EXM_LATCH_CMD, "EX/M", 10)  
                    if data:
                        decoded = decode_ex_m_latch_packed(data)  # ✅ NUEVA función
                        if decoded:
                            latches = {'ex_m': decoded, 'ex_m_raw': data}
                            display_latches(latches)
                elif latch_choice == "4":
                    data = read_single_latch(ser, READ_MWB_LATCH_CMD, "M/WB", 9)  
                    if data:
                        decoded = decode_m_wb_latch_packed(data)  # ✅ NUEVA función
                        if decoded:
                            latches = {'m_wb': decoded, 'm_wb_raw': data}
                            display_latches(latches)
                        else:
                            print("Opción no válida")
            except Exception as e:
                print(f"Error leyendo latch específico: {e}")
                clear_serial_buffers(ser)
        
        elif accion == "6":
            # Avanzar un paso (STEP)
            print("\n=== AVANZAR UN PASO ===")
            clear_serial_buffers(ser)
            send_command(ser, STEP_CMD)
            print("Comando STEP enviado para avanzar un paso.")
        
        elif accion == "7":
            # Reset
            clear_serial_buffers(ser)
            send_command(ser, RESET_CMD)
            print("Comando RESET enviado.")
            time.sleep(0.5)
            clear_serial_buffers(ser)
            
        elif accion == "8":
            print("Saliendo del programa.")
            break
        else:
            print("Opción no válida.")

    ser.close()
    print("UART cerrado.")

if __name__ == "__main__":
    main()