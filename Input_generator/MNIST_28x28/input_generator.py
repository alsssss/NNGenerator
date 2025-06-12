import os
import numpy as np

here = os.path.dirname(os.path.abspath(__file__))  
parent_dir = os.path.join(here, os.pardir)  
serial_dir = os.path.join(parent_dir, "Serial_communication")
os.makedirs(serial_dir, exist_ok=True)

data = np.load("sample4_4.npy").flatten()
data_uint8 = (data * 255).astype(np.uint8)
min_value = 0
max_value = 255

txt_path = os.path.join(serial_dir, "sample4_4_28x28.txt")
with open(txt_path, "w") as f:
    f.write("txt\n")
    f.write(f"{min_value}\n")
    f.write(f"{max_value}\n")
    
    for value in data_uint8:
        f.write(f"{value}\n")

image_2d = data_uint8.reshape(28, 28)

pgm_path = os.path.join(serial_dir, "sample4_4_28x28.pgm")
with open(pgm_path, "w") as f:
    f.write("P2\n")           # This is P2 PGM
    f.write("28 28\n")        # This is the size of the dataset
    f.write("255\n")          # Maximum value
    for row in image_2d:
        f.write(" ".join(map(str, row)) + "\n")