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

def receive_ack(ser):
    """Recibe y verifica un ACK con timeout"""
    timeout_count = 0
    while timeout_count < 10:  # 1 segundo de timeout
        if ser.in_waiting > 0:
            ack = ser.read(1)
            print(f"ACK recibido: {ack.hex() if ack else 'None'}")
            if ack == b'\xAA':
                return True
            else:
                print(f"ACK incorrecto: {ack.hex()}")
                return False
        time.sleep(0.1)
        timeout_count += 1
    
    print("TIMEOUT: No se recibió ACK")
    return False

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

def receive_regs_data(ser):
    """Recibe datos de 32 registros (32 * 4 = 128 bytes)"""
    print("Recibiendo registros...")
    
    # Recibir todos los bytes de los registros de una vez
    reg_data = receive_bytes(ser, 128, "registros")
    if reg_data is None:
        return []
    
    # Convertir bytes a lista de registros (32 registros de 4 bytes cada uno)
    regs_data = []
    for i in range(32):
        start_idx = i * 4
        end_idx = start_idx + 4
        reg_bytes = reg_data[start_idx:end_idx]
        
        # Mantener big endian (comunicación actual)
        reg_value = int.from_bytes(reg_bytes, 'big')
        
        regs_data.append(reg_value)
        
        # Mostrar bytes individuales para debug si quieres
        print(f"Registro ${i:02}: 0x{reg_value:08X}")
    
    return regs_data

def receive_mem_data(ser):
    """Recibe datos de 64 palabras de memoria (64 * 4 = 256 bytes)"""
    print("Recibiendo memoria...")
    
    # Recibir todos los bytes de memoria de una vez
    mem_data = receive_bytes(ser, 256, "memoria")
    if mem_data is None:
        return []
    
    # Convertir bytes a lista de palabras (64 palabras de 4 bytes cada una)
    mem_words = []
    for i in range(64):
        start_idx = i * 4
        end_idx = start_idx + 4
        word_bytes = mem_data[start_idx:end_idx]
        word_value = int.from_bytes(word_bytes, 'big')
        mem_words.append(word_value)
        print(f"Memoria[{i*4:03}]: 0x{word_value:08X}")
    
    return mem_words

def receive_latches_data(ser):
    """Recibe datos de latches (43 bytes)"""
    print("Recibiendo latches...")
    
    latches_data = receive_bytes(ser, 43, "latches")
    if latches_data is None:
        return b''
    
    print(f"Latches recibidos: {latches_data.hex()}")
    return latches_data

def send_command_with_ack(ser, cmd):
    """Envía un comando y espera ACK usando la función receive_ack"""
    print(f"Enviando comando: 0x{cmd:02X}")
    ser.write(bytes([cmd]))
    ser.flush()
    
    return receive_ack(ser)

def send_bytes_with_ack(ser, data):
    """Envía bytes y verifica ACK con timeout usando receive_ack"""
    for b in data:
        print(f"Enviando byte: 0x{b:02X}")
        ser.write(bytes([b]))
        ser.flush()  # Forzar envío inmediato
        
        if not receive_ack(ser):
            raise Exception("Error enviando byte, ACK no recibido")

def send_instruction(ser, instruction):
    """Envía una instrucción de 32 bits (4 bytes) con ACK"""
    instr_bytes = instruction.to_bytes(4, 'big')
    print("Enviando instrucción (bytes):", [f"0x{b:02X}" for b in instr_bytes])
    send_bytes_with_ack(ser, instr_bytes)

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
        accion = input("¿Qué desea hacer? (1: Cargar instrucciones, 2: Ejecutar programa, 3: Reiniciar, 4: Salir): ")
        
        if accion == "1":
            # Limpiar buffers antes de cargar instrucciones
            clear_serial_buffers(ser)
            
            # Enviar comando LOAD_INSTRUCTION y esperar ACK
            if not send_command_with_ack(ser, LOAD_INSTRUCTION_CMD):
                print("Error: No se pudo enviar comando LOAD_INSTRUCTION")
                continue
                
            print("Comando LOAD_INSTRUCTION enviado y confirmado.")
            
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
            
            # Enviar comando RUN y esperar ACK
            if not send_command_with_ack(ser, RUN_CMD):
                print("Error: No se pudo enviar comando RUN")
                continue
                
            print("Comando RUN enviado y confirmado. Esperando resultados...")
            
            try:
                # Recibir datos usando las nuevas funciones
                regs = receive_regs_data(ser)
                mem = receive_mem_data(ser)
                latches = receive_latches_data(ser)
                
                print("Recepción finalizada.")
                print("\n=== RESUMEN REGISTROS ===")
                for idx, val in enumerate(regs):
                    if val != 0:  # Solo mostrar registros no cero
                        print(f"${idx:02}: 0x{val:08X}")
                
                print("\n=== RESUMEN MEMORIA ===")
                for idx, val in enumerate(mem):
                    if val != 0:  # Solo mostrar memoria no cero
                        print(f"Mem[{idx*4:03}]: 0x{val:08X}")
                
                print("\n=== LATCHES (hex) ===")
                print(latches.hex())
                
            except Exception as e:
                print(f"Error recibiendo datos: {e}")
                clear_serial_buffers(ser)
                
        elif accion == "3":
            # Limpiar buffers antes de reset
            clear_serial_buffers(ser)
            
            # Enviar comando RESET (sin esperar ACK para reset)
            print(f"Enviando comando RESET: 0x{RESET_CMD:02X}")
            ser.write(bytes([RESET_CMD]))
            ser.flush()
            print("Comando RESET enviado.")
            time.sleep(0.5)  # Esperar que el reset se complete
            
            # Limpiar buffers después del reset
            clear_serial_buffers(ser)
            
        elif accion == "4":
            print("Saliendo del programa.")
            break
        else:
            print("Opción no válida.")

    ser.close()
    print("UART cerrado.")

if __name__ == "__main__":
    main()