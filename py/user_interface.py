import serial
import time

SERIAL_PORT          = '/dev/ttyUSB1'
BAUD_RATE            = 19200
BYTESIZE             = serial.EIGHTBITS
STOPBITS             = serial.STOPBITS_ONE
PARITY               = serial.PARITY_NONE
LOAD_INSTRUCTION_CMD = 0x02
RUN_CMD              = 0x05
RESET_CMD            = 0x0C

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
        if mnemonic in ["SLL", "SRL", "SRA"]:
            # SLL rd, rt, sa
            rd = REGS[operands[0]]
            rt = REGS[operands[1]]
            sa = int(operands[2])
            rs = 0
        elif mnemonic in ["SLLV", "SRLV", "SRAV"]:
            # SLLV rd, rt, rs
            rd = REGS[operands[0]]
            rt = REGS[operands[1]]
            rs = REGS[operands[2]]
            sa = 0
        else:
            # ADD rd, rs, rt
            rd = REGS[operands[0]]
            rs = REGS[operands[1]]
            rt = REGS[operands[2]]
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

def send_bytes(ser, data):
    for b in data:
        print(f"Enviando byte: 0x{b:02X}")
        ser.write(bytes([b]))
        while True:
            ack = ser.read(1)
            print(f"Recibido: {ack.hex() if ack else 'None'}")  # Imprime el valor recibido
            if ack == b'\xAA':
                print("ACK recibido.")
                break
            print("Esperando ACK...")
            time.sleep(0.1)
        ser.flush()

def send_instruction(ser, instruction):
    instr_bytes = instruction.to_bytes(4, 'big')
    print("Enviando instrucción (bytes):", [f"0x{b:02X}" for b in instr_bytes])
    send_bytes(ser, instr_bytes)

def receive_regs_data(ser):
    print("Recibiendo registros...")
    regs = b''
    while len(regs) < 32:  # 32 registros de 4 bytes cada uno
        chunk = ser.read(32 - len(regs))
        if not chunk:
            print("Error: no se recibieron más datos de registros")
            break
        regs += chunk
    return regs

def receive_mem_data(ser):
    print("Recibiendo memoria...")
    mem = b''
    while len(mem) < 256:  # 256 bytes de memoria (64 palabras de 4 bytes)
        chunk = ser.read(256 - len(mem))
        if not chunk:
            print("Error: no se recibieron más datos de memoria")
            break
        mem += chunk
    return mem

def receive_latches_data(ser):
    print("Recibiendo latches...")
    latches = b''
    while len(latches) < 43:  # 43 bytes de latches
        chunk = ser.read(43 - len(latches))
        if not chunk:
            print("Error: no se recibieron más datos de latches")
            break
        latches += chunk
    return latches

def main():
    try:
        ser = serial.Serial(
            port=SERIAL_PORT,
            baudrate=BAUD_RATE,
            bytesize=BYTESIZE,
            stopbits=STOPBITS,
            parity=PARITY,
            timeout=None
        )
    except Exception as e:
        print(f"Error al abrir el puerto serial: {e}")
        return
    
    print("Puerto serie {} abierto a {} bauds.".format(SERIAL_PORT, BAUD_RATE))

    # 2. Elegir acción: cargar instrucciones o ejecutar
    while True:
        accion = input("¿Qué desea hacer? (1: Cargar instrucciones, 2: Ejecutar programa, 3: Reiniciar, 4: Salir): ")
        if accion == "1":
            # Enviar comando LOAD_INSTRUCTION
            send_bytes(ser, bytes([LOAD_INSTRUCTION_CMD]))
            print("Comando LOAD_INSTRUCTION enviado.")
            time.sleep(0.1)
            while True:
                instr_str = input("Ingrese instrucción (ej: ADD $v0 $v1 $a0, HALT para terminar): ")
                if instr_str.strip().upper() == "HALT":
                    # Enviar instrucción HALT (0x3F)
                    send_instruction(ser, (0x3F << 26) | (0 << 21) | (0 << 16) | 0)
                    print("HALT enviado.")
                    break
                try:
                    mnemonic, operands = parse_instruction(instr_str)
                    instr_bin = encode_instruction(mnemonic, operands)
                    print(f"Instrucción binaria: {instr_bin:032b}")
                    send_instruction(ser, instr_bin)
                    time.sleep(0.1)
                except Exception as e:
                    print("Error:", e)
        elif accion == "2":
            # Enviar comando RUN
            send_bytes(ser, bytes([RUN_CMD]))
            print("Comando RUN enviado. Esperando resultados del pipeline...")
            time.sleep(0.1)
            # Recibir datos de debug_unit
            regs = receive_regs_data(ser)
            mem = receive_mem_data(ser)
            latches = receive_latches_data(ser)
            print("Recepción finalizada.")
            print("\n=== REGISTROS ===")
            for i in range(0, len(regs), 4):
                word = int.from_bytes(regs[i:i+4], 'big')
                print(f"${i//4:02}: 0x{word:08X}")
            print("\n=== MEMORIA ===")
            for i in range(0, len(mem), 4):
                word = int.from_bytes(mem[i:i+4], 'big')
                print(f"Mem[{i:03}]: 0x{word:08X}")
            print("\n=== LATCHES (hex) ===")
            print(latches.hex())
        elif accion == "3":
            # Enviar comando RESET
            send_bytes(ser, bytes([RESET_CMD]))
            print("Comando RESET enviado.")
            time.sleep(0.1)
        elif accion == "4":
            print("Saliendo del programa.")
            break
        else:
            print("Opción no válida.")

    ser.close()
    print("UART cerrado.")

if __name__ == "__main__":
    main()