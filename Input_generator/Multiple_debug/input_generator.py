import numpy as np
import os

npy_path = "sample1.npy"
here = os.path.dirname(os.path.abspath(__file__))  
parent_dir = os.path.join(here, os.pardir)  
serial_dir = os.path.join(parent_dir, "Serial_communication/debug")
os.makedirs(serial_dir, exist_ok=True)


txt_input_path = os.path.join(serial_dir, "sample1_debug.txt")
txt_data_path = os.path.join(serial_dir, "sample1_other.txt")
pgm_path = os.path.join(serial_dir, "sample1_debug.pgm")

# === Load .npy and extract data ===
data = np.load(npy_path, allow_pickle=True).flatten()[0]


# Extract input vector (assuming shape (1, N))
input_vector = data["input"][0]

print("Original input vector sample (first 20):", input_vector[:20])

# Scale to 0-255 uint8
data_uint8 = (input_vector * 255).round().astype(np.uint8)
min_value = 0                # This is the minimum value that can be transferred
max_value = 255              # This is the maximum value that can be transferred

print("Scaled uint8 sample (first 20):", data_uint8[:20])

# Write scaled input to txt file
txt_path = os.path.join(serial_dir, "input.txt")
with open(txt_path, "w") as f:
    f.write("txt\n")
    f.write(f"{min_value}\n")
    f.write(f"{max_value}\n")
    for val in data_uint8:
        f.write(f"{val}\n")

print(f"✅ Wrote scaled input to {txt_path}")

# Write other keys if any
for key in data:
    if key != "input":
        content = data[key]
        if isinstance(content, np.ndarray):
            content = content.flatten()
        txt_other_path = os.path.join(serial_dir, f"{key}.txt")
        with open(txt_other_path, "w") as f:
            for val in content:
                f.write(f"{val}\n")
        print(f"✅ Wrote {key} to {txt_other_path}")
# === Save as .pgm image (only if 16x16 expected) ===
try:
    image_2d = data_uint8.reshape(16, 16)
    with open(pgm_path, "w") as f:
        f.write("P2\n")
        f.write("16 16\n")
        f.write("255\n")
        for row in image_2d:
            f.write(" ".join(map(str, row)) + "\n")
    print(f"Saved PGM image to: {pgm_path}")
except:
    print("Could not reshape to 16x16 for PGM.")










