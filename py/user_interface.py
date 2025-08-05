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
READ_REG_CMD         = 0x06
READ_MEM_CMD         = 0x07
READ_LATCHES_CMD     = 0x08

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

def read_latches(ser):
    """Lee los latches del sistema usando READ_LATCHES_CMD con protocolo de confirmación"""
    print("Leyendo latches del pipeline...")

    # Limpiar buffers antes de la operación
    clear_serial_buffers(ser)

    # PASO 1: Enviar comando READ_LATCHES
    send_command(ser, READ_LATCHES_CMD)
    print("Comando READ_LATCHES enviado.")
    time.sleep(0.1)

    try:
        # PASO 2: Recibir 64 bits (8 bytes) del registro IF/ID
        print("\n=== RECIBIENDO REGISTRO IF/ID (64 bits) ===")
        if_id_data = receive_bytes(ser, 8, "registro IF/ID")
        if if_id_data is None:
            return None
        
        # PASO 3: Enviar confirmación para IF/ID
        print("Enviando confirmación para IF/ID...")
        ser.write(bytes([0x01]))  # Confirmación
        ser.flush()
        time.sleep(0.05)

        # PASO 4: Recibir 130 bits (17 bytes) del registro ID/EX
        print("\n=== RECIBIENDO REGISTRO ID/EX (130 bits) ===")
        id_ex_data = receive_bytes(ser, 17, "registro ID/EX")  # 130 bits = 16.25 bytes → 17 bytes
        if id_ex_data is None:
            return None
        
        # PASO 5: Enviar confirmación para ID/EX
        print("Enviando confirmación para ID/EX...")
        ser.write(bytes([0x01]))  # Confirmación
        ser.flush()
        time.sleep(0.05)

        # PASO 6: Recibir 76 bits (10 bytes) del registro EX/M
        print("\n=== RECIBIENDO REGISTRO EX/M (76 bits) ===")
        ex_m_data = receive_bytes(ser, 10, "registro EX/M")  # 76 bits = 9.5 bytes → 10 bytes
        if ex_m_data is None:
            return None
        
        # PASO 7: Enviar confirmación para EX/M
        print("Enviando confirmación para EX/M...")
        ser.write(bytes([0x01]))  # Confirmación
        ser.flush()
        time.sleep(0.05)

        # PASO 8: Recibir 70 bits (9 bytes) del registro M/WB
        print("\n=== RECIBIENDO REGISTRO M/WB (70 bits) ===")
        m_wb_data = receive_bytes(ser, 9, "registro M/WB")  # 70 bits = 8.75 bytes → 9 bytes
        if m_wb_data is None:
            return None

        # PASO 9: Mostrar TODO el contenido RAW sin formateo
        print("\n" + "="*80)
        print("=== CONTENIDO RAW DE LOS LATCHES DEL PIPELINE ===")
        print("="*80)
        
        # IF/ID - Mostrar todos los bytes
        print(f"\n🔍 REGISTRO IF/ID (64 bits / 8 bytes):")
        print(f"   Bytes HEX: {[f'0x{b:02X}' for b in if_id_data]}")
        print(f"   Bytes DEC: {list(if_id_data)}")
        if_id_hex = ''.join(f'{b:02X}' for b in if_id_data)
        print(f"   Hex string: {if_id_hex}")
        if_id_bin = ''.join(f'{b:08b}' for b in if_id_data)
        print(f"   Binario: {if_id_bin}")
        print(f"   Como int: {int.from_bytes(if_id_data, 'big')}")
        
        # ID/EX - Mostrar todos los bytes
        print(f"\n🔍 REGISTRO ID/EX (130 bits / 17 bytes):")
        print(f"   Bytes HEX: {[f'0x{b:02X}' for b in id_ex_data]}")
        print(f"   Bytes DEC: {list(id_ex_data)}")
        id_ex_hex = ''.join(f'{b:02X}' for b in id_ex_data)
        print(f"   Hex string: {id_ex_hex}")
        id_ex_bin = ''.join(f'{b:08b}' for b in id_ex_data)
        print(f"   Binario: {id_ex_bin}")
        print(f"   Longitud binario: {len(id_ex_bin)} bits")
        
        # EX/M - Mostrar todos los bytes
        print(f"\n🔍 REGISTRO EX/M (76 bits / 10 bytes):")
        print(f"   Bytes HEX: {[f'0x{b:02X}' for b in ex_m_data]}")
        print(f"   Bytes DEC: {list(ex_m_data)}")
        ex_m_hex = ''.join(f'{b:02X}' for b in ex_m_data)
        print(f"   Hex string: {ex_m_hex}")
        ex_m_bin = ''.join(f'{b:08b}' for b in ex_m_data)
        print(f"   Binario: {ex_m_bin}")
        print(f"   Longitud binario: {len(ex_m_bin)} bits")
        
        # M/WB - Mostrar todos los bytes
        print(f"\n🔍 REGISTRO M/WB (70 bits / 9 bytes):")
        print(f"   Bytes HEX: {[f'0x{b:02X}' for b in m_wb_data]}")
        print(f"   Bytes DEC: {list(m_wb_data)}")
        m_wb_hex = ''.join(f'{b:02X}' for b in m_wb_data)
        print(f"   Hex string: {m_wb_hex}")
        m_wb_bin = ''.join(f'{b:08b}' for b in m_wb_data)
        print(f"   Binario: {m_wb_bin}")
        print(f"   Longitud binario: {len(m_wb_bin)} bits")
        
        print("\n" + "="*80)
        print("✅ DUMP RAW COMPLETADO - Revisar si se reciben todos los datos")
        print("="*80)
        
        return {
            'if_id': if_id_data,
            'id_ex': id_ex_data,
            'ex_m': ex_m_data,
            'm_wb': m_wb_data
        }
        
    except Exception as e:
        print(f"❌ Error durante la lectura de latches: {e}")
        clear_serial_buffers(ser)
        return None


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
        accion = input("¿Qué desea hacer? (1: Cargar instrucciones, 2: Ejecutar programa, 3: Leer registro, 4: Leer memoria, 5: Leer latches, 6: Reiniciar, 7: Salir): ")

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
            # Leer latches (nueva funcionalidad)
            print("\n=== LEER LATCHES ===")
            try:
                read_latches(ser)
            except Exception as e:
                print(f"Error leyendo latches: {e}")
                clear_serial_buffers(ser)
        elif accion == "6":
            # Limpiar buffers antes de reset
            clear_serial_buffers(ser)
            
            # Enviar comando RESET SIN esperar ACK
            send_command(ser, RESET_CMD)
            print("Comando RESET enviado.")
            time.sleep(0.5)  # Esperar que el reset se complete
            
            # Limpiar buffers después del reset
            clear_serial_buffers(ser)
            
        elif accion == "7":
            print("Saliendo del programa.")
            break
        else:
            print("Opción no válida.")

    ser.close()
    print("UART cerrado.")

if __name__ == "__main__":
    main()