# import socket
# import time

# client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# client.connect(("192.168.1.136", 4015))
# print("------ lwIP TCP Encoder-Decoder Server CONNECTED ------")

# num_data_frames = 15000

# num_tx_bytes = num_data_frames*80

# num_rx_bytes = num_data_frames*88 
# num_rx_packet_bytes = num_rx_bytes 

# start_time = time.perf_counter()

# client.send(num_tx_bytes.to_bytes(num_tx_bytes, 'little'))

# received = 0
# while received < num_rx_bytes:
#     data = client.recv(num_rx_packet_bytes)
#     received += len(data)
#     print(f"Received {received} bytes total, {len(data)} in this recv")

# client.close()

# end_time = time.perf_counter()

# elapsed_time = end_time - start_time
# print(f"time.perf_counter: {elapsed_time:.6f} seconds")








import socket
import re
import time

def process_gen_poly(octal_str, constraint_length):
    """Convert octal string to binary, take rightmost constraint_length bits,
    reverse bit order (little endian), and pad to 9 bits"""
    num = int(octal_str, 8)
    binary_str = bin(num)[2:]  # Convert to binary without '0b' prefix
    # Take rightmost constraint_length bits
    rightmost_bits = binary_str[-constraint_length:] if len(binary_str) >= constraint_length else binary_str.zfill(constraint_length)
    # Reverse bit order (little endian)
    little_endian = rightmost_bits[::-1]
    # Pad with leading zeros to make it 9 bits
    padded = little_endian.zfill(9)
    return int(padded, 2)

def process_prv_state(prv_state_str, constraint_length):
    """Convert decimal string to binary, take rightmost constraint_length-1 bits,
    reverse bit order (little endian), and pad to 8 bits"""
    decimal_value = int(prv_state_str)
    binary_str = bin(decimal_value)[2:]  # Convert to binary without '0b' prefix
    # Take rightmost constraint_length-1 bits
    rightmost_bits = binary_str[-(constraint_length-1):] if len(binary_str) >= (constraint_length-1) else binary_str.zfill(constraint_length-1)
    # Reverse bit order (little endian)
    little_endian = rightmost_bits[::-1]
    # Pad with leading zeros to make it 8 bits
    padded = little_endian.zfill(8)
    return int(padded, 2)

def parse_golden_file(filename):
    samples = []
    with open(filename, 'r') as file:
        content = file.read()
        
        sample_sections = content.split('=== Sample ')[1:]
        
        for section in sample_sections:
            sample_num, sample_content = section.split(' ===', 1)
            
            # Extract all fields
            constraint_length = int(re.search(r'constraint_length: (\d+)', sample_content).group(1))
            code_rate = re.search(r'i_code_rate: (\d+)', sample_content)
            gen_poly = re.search(r'i_gen_poly: (\d+) (\d+) (\d+)', sample_content)
            prv_state = re.search(r'i_prv_encoder_state: (\d+)', sample_content)
            enc_frame = re.search(r'i_encoder_data_frame: (\d+)', sample_content)
            dec_frame = re.search(r'i_decoder_data_frame: (\d+)', sample_content)
            enc_output = re.search(r'o_encoder_data: (\d+)', sample_content)
            dec_output = re.search(r'o_decoder_data: (\d+)', sample_content)
            
            if gen_poly and prv_state and enc_frame and dec_frame and code_rate and enc_output and dec_output:
                # Process code rate (0b1 for rate 3, 0b0 for rate 2)
                code_rate_val = int(code_rate.group(1))
                i_code_rate = 0b1 if code_rate_val == 3 else 0b0
                
                # Process polynomials
                poly1 = process_gen_poly(gen_poly.group(1), constraint_length)
                poly2 = process_gen_poly(gen_poly.group(2), constraint_length)
                poly3 = process_gen_poly(gen_poly.group(3), constraint_length) if gen_poly.group(3) != '0' else 0
                
                # Combine polynomials
                i_gen_poly_flat = (poly3 << 18) | (poly2 << 9) | poly1
                
                # Process previous state
                i_prv_encoder_state = process_prv_state(prv_state.group(1), constraint_length)

                sample = {
                    'constraint_length': constraint_length,
                    'i_code_rate': i_code_rate,
                    'i_gen_poly_flat': i_gen_poly_flat,
                    'i_encoder_data_frame': int(enc_frame.group(1), 2),
                    'i_decoder_data_frame': int(dec_frame.group(1), 2),
                    'i_prv_encoder_state': i_prv_encoder_state,
                    'o_encoder_data': enc_output.group(1),
                    'o_decoder_data': dec_output.group(1)
                }
                samples.append(sample)
    
    return samples

def create_large_packet(samples, num_samples=15000):
    """Create a single large packet containing num_samples samples"""
    packet_bytes = bytearray()
    
    for i in range(num_samples):
        if i >= len(samples):
            break
            
        sample = samples[i]
        
        # Control field (64 bits = 8 bytes)
        control_field = (sample['i_prv_encoder_state'] << 28) | \
                        (sample['i_code_rate'] << 27) | \
                        sample['i_gen_poly_flat']
        packet_bytes.extend(control_field.to_bytes(8, 'little'))
        
        # Encoder data (192 bits = 24 bytes)
        encoder_bytes = sample['i_encoder_data_frame'].to_bytes(24, 'little')
        packet_bytes.extend(encoder_bytes)
        
        # Decoder data (384 bits = 48 bytes)
        decoder_bytes = sample['i_decoder_data_frame'].to_bytes(48, 'little')
        packet_bytes.extend(decoder_bytes)
    
    return packet_bytes

def reverse_bytes(data):
    """Reverse the byte order of the given data while preserving bit order within bytes"""
    return bytes(reversed(data))

def bytes_to_binary_string(byte_data, bytes_per_line=8):
    """Convert bytes to formatted binary string"""
    binary_lines = []
    for i in range(0, len(byte_data), bytes_per_line):
        chunk = byte_data[i:i+bytes_per_line]
        line_parts = []
        for byte in chunk:
            line_parts.append(f"{byte:08b}")
        binary_lines.append(' '.join(line_parts))
    return '\n'.join(binary_lines)

def clean_binary_string(binary_str):
    """Remove all spaces and newlines from binary string"""
    return binary_str.replace(' ', '').replace('\n', '')

def compare_outputs(golden_samples, received_data):
    """Compare received data with golden outputs and generate scoreboard"""
    total_samples = len(golden_samples)
    matching_samples = 0
    mismatched_samples = 0
    mismatch_details = []
    
    sample_count = len(received_data) // 88
    
    for i in range(min(sample_count, total_samples)):
        golden_sample = golden_samples[i]
        sample_bytes = received_data[i*88 : (i+1)*88]
        
        # Split and reverse byte order
        encoder_output = reverse_bytes(sample_bytes[:72])
        decoder_output = reverse_bytes(sample_bytes[72:])
        
        # Convert to clean binary strings
        received_encoder = clean_binary_string(bytes_to_binary_string(encoder_output))
        received_decoder = clean_binary_string(bytes_to_binary_string(decoder_output))
        
        # Get golden outputs
        golden_encoder = golden_sample['o_encoder_data']
        golden_decoder = golden_sample['o_decoder_data']
        
        # Compare
        encoder_match = received_encoder == golden_encoder
        decoder_match = received_decoder == golden_decoder
        
        if encoder_match and decoder_match:
            matching_samples += 1
        else:
            mismatched_samples += 1
            mismatch_details.append({
                'sample_num': i + 1,
                'encoder_match': encoder_match,
                'decoder_match': decoder_match,
                'received_encoder': received_encoder,
                'golden_encoder': golden_encoder,
                'received_decoder': received_decoder,
                'golden_decoder': golden_decoder
            })
    
    # Generate scoreboard
    scoreboard = "=== SCOREBOARD ===\n"
    scoreboard += f"Total samples compared: {sample_count}\n"
    scoreboard += f"Matching samples: {matching_samples}\n"
    scoreboard += f"Mismatched samples: {mismatched_samples}\n\n"
    
    if mismatched_samples == 0:
        scoreboard += "All samples matched perfectly!\n"
    else:
        scoreboard += "Mismatch details:\n"
        for detail in mismatch_details:
            scoreboard += f"\nSample {detail['sample_num']}:\n"
            if not detail['encoder_match']:
                scoreboard += "  Encoder output mismatch!\n"
                # Find first mismatch position
                for pos in range(min(len(detail['received_encoder']), len(detail['golden_encoder']))):
                    if detail['received_encoder'][pos] != detail['golden_encoder'][pos]:
                        scoreboard += f"  First mismatch at bit position {pos}\n"
                        break
            if not detail['decoder_match']:
                scoreboard += "  Decoder output mismatch!\n"
                # Find first mismatch position
                for pos in range(min(len(detail['received_decoder']), len(detail['golden_decoder']))):
                    if detail['received_decoder'][pos] != detail['golden_decoder'][pos]:
                        scoreboard += f"  First mismatch at bit position {pos}\n"
                        break
    
    return scoreboard

def process_received_data(data, golden_samples, filename='received_data.txt'):
    """Process received data and save in text format with binary representation"""
    with open(filename, 'w') as f:
        sample_count = len(data) // 88
        
        for i in range(sample_count):
            sample_bytes = data[i*88 : (i+1)*88]
            
            # Split and reverse byte order
            encoder_output = reverse_bytes(sample_bytes[:72])
            decoder_output = reverse_bytes(sample_bytes[72:])
            
            # Write to file
            f.write(f"[Sample {i+1}]\n")
            f.write("Encoder Output (72 bytes):\n")
            f.write(bytes_to_binary_string(encoder_output) + "\n")
            f.write("\nDecoder Output (16 bytes):\n")
            f.write(bytes_to_binary_string(decoder_output) + "\n")
            f.write("="*60 + "\n\n")
    
    print(f"[STATUS] {sample_count} processed data frames saved to {filename}")
    
    # Compare with golden outputs
    scoreboard = compare_outputs(golden_samples, data)
    with open('scoreboard.txt', 'w') as f:
        f.write(scoreboard)
    print("[STATUS] Scoreboard generated in scoreboard.txt")

def main():

    num_data_frame = 100

    rx_data_group = num_data_frame*88
    rx_packet_size = rx_data_group

    golden_samples = parse_golden_file('golden_input_output.txt')
    
    if not golden_samples:
        print("Error: No samples found in input file")
        return


    large_packet = create_large_packet(golden_samples, num_data_frame)


    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect(("192.168.1.136", 4015))
    print("------ lwIP TCP Encoder-Decoder Server CONNECTED ------")
    
    start_time = time.perf_counter()

    # Send the single large packet
    print(f"[STATUS] Sending {num_data_frame} data frames ({len(large_packet)} bytes)")
    client.send(large_packet)

    # Receive response
    received_data = bytearray()
    received = 0
    while received < rx_data_group:
        data = client.recv(rx_packet_size)
        received += len(data)
        print(f"Received {received} bytes total, {len(data)} in this recv")
        received_data.extend(data)

    client.close()

    end_time = time.perf_counter()

    elapsed_time = end_time - start_time
    print(f"Latency: {elapsed_time:.6f} seconds")

    # Process and compare data
    process_received_data(received_data, golden_samples)

if __name__ == "__main__":
    main()