import serial
import time

def send_data(serial_port, data):
    try:
        # �򿪴���
        ser = serial.Serial(serial_port, baudrate=9600, timeout=1)

        # ������ת��Ϊʮ�����Ƹ�ʽ
        hex_data = format(data, '02x')

        # ��������
        ser.write(bytearray.fromhex(hex_data))

        # �رմ���
        ser.close()

        print(f"�ɹ���������: {hex_data}")
    except Exception as e:
        print(f"��������ʱ����: {str(e)}")

# ���ô��ں�
serial_port = 'COM1'  

# ����Ҫ���͵�8λ����
data_to_send = 0xAB

# ��������
send_data(serial_port, data_to_send)
