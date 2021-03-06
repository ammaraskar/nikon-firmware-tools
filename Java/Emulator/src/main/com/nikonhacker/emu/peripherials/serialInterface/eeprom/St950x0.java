package com.nikonhacker.emu.peripherials.serialInterface.eeprom;

import com.nikonhacker.Format;
import com.nikonhacker.emu.peripherials.serialInterface.SerialDevice;
import com.nikonhacker.emu.peripherials.serialInterface.SpiSlaveDevice;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Arrays;

/**
 * This implementation is based on the ST950x0 datasheet at
 * http://www.st.com/st-web-ui/static/active/en/resource/technical/document/datasheet/CD00001755.pdf
 * This abstract class has no given size. Subclasses (95010, 95020, 95040) are the ones to use.
 *
 * Note: RDSR/WRSR commands during READ/WRITE is not implemented
 */
public abstract class St950x0 extends SpiSlaveDevice {

    public static final byte DUMMY_BYTE = 0x0;

    public static final int WREN   = 0b0000_0110; // WREN Set Write Enable Latch
    public static final int WRDI   = 0b0000_0100; // WRDI Reset Write Enable Latch
    public static final int RDSR   = 0b0000_0101; // RDSR Read Status Register
    public static final int WRSR   = 0b0000_0001; // WRSR Write Status Register
    public static final int READ0  = 0b0000_0011; // READ Read Data from Memory Array (0)
    public static final int READ1  = 0b0000_1011; // READ Read Data from Memory Array (1)
    public static final int WRITE0 = 0b0000_0010; // WRITE Write Data to Memory Array (0)
    public static final int WRITE1 = 0b0000_1010; // WRITE Write Data to Memory Array (1)

    private String name;

    int statusRegister = 0b1111_0000;
    private byte[] memory;
    private boolean writeProtected = false;
    private int write1offset = 0;

    // Current command processing state
    private Command currentCommand = null;
    private Integer currentAddress = null;

    private int numBits = 8;

    public enum Command {WREN, WRDI, RDSR, WRSR, READ0, READ1, WRITE0, WRITE1}

    public St950x0(String name, int size) {
        super();
        this.name = name;
        memory = new byte[size];

        if (size > 0xFF) {
            write1offset = 0x100;
        }

        clear();
    }

    public byte[] getMemory() {
        return memory;
    }

    public void loadArray(byte[] contents) {
        System.arraycopy(contents, 0, memory, 0, memory.length);
    }

    public void clear() {
        // Default fill = 0xFF
        Arrays.fill(memory, (byte) 0xFF);
        // Dummy fill to test
//        for (int i = 0; i < memory.length; i++) {
//            memory[i] = (byte)(0xFF - i);
//        }
    }

    public boolean isWriteLatchEnabled() {
        return (statusRegister & 0b00000010) != 0;
    }

    public void setWriteLatchEnabled() {
        statusRegister = statusRegister | 0b00000010;
    }

    public void clearWriteLatchEnabled() {
        statusRegister = statusRegister & 0b11111101;
    }

    public void loadBinary(File file) throws IOException {
        if (file == null) {
            throw new IOException("Error: file is null !");
        }
        if (file.length() != memory.length) {
            throw new IOException("Error: File '" + file.getAbsolutePath() + "' is not " + memory.length + " bytes long!");
        }
        FileInputStream fis = new FileInputStream(file);
        fis.read(memory);
        fis.close();
    }

    public void saveBinary(File file) throws IOException {
        if (file == null) {
            throw new IOException("Error: file is null !");
        }
        FileOutputStream fos = new FileOutputStream(file);
        fos.write(memory);
        fos.close();
    }

    @Override
    public void setSelected(boolean selected) {
        if (!this.selected && selected) {
            // transition to selected state : reset state
            if(currentCommand == St950x0.Command.WRITE0 || currentCommand == St950x0.Command.WRITE1) {
                // Ending a write command, disable the write latch
                clearWriteLatchEnabled();
            }
            currentCommand = null;
            currentAddress = null;
        }
        super.setSelected(selected);
    }

    /**
     * Note: in Nikon cameras, pin 3 (!W) is set to Vcc
     * In other words, all write operations are available
     * @param writeProtected
     */
    public void setWriteProtected(boolean writeProtected) {
        clearWriteLatchEnabled();
        this.writeProtected = writeProtected;
    }

    /**
     * Note: in Nikon cameras, pin 7 (!HOLD) is set to Vcc
     * In other words, no HOLD condition can occur
     * @param hold
     */
    public void setHold(boolean hold) {
        // This has no effect.
    }

    public Integer read() {
        if (currentCommand == null) {
            // This clock is due to the command being received. Return a dummy byte
            return (int) DUMMY_BYTE;
        }
        switch (currentCommand) {
            case RDSR:
                // This clock phase is here to reply. Let's reply with the status register (over and over)
                return statusRegister;
            case READ0:
            case READ1:
                if (currentAddress == null) {
                    // This clock is due to the address being received. Return a dummy byte
                    return (int) DUMMY_BYTE;
                }
                else {
                    // This clock phase is here to reply. Let's reply with the memory value
                    int value = memory[currentAddress];
                    // Prepare next read by incrementing address, wrapping at memory the boundary
                    currentAddress = (currentAddress + 1) % memory.length;
                    return value;
                }
            case WRITE0:
            case WRITE1:
            case WRSR:
                // This clock is due to the address or values being received. Return a dummy byte
                return (int) DUMMY_BYTE;
            default:
                System.err.println("Unhandled command '" + currentCommand + "', returning 0x00");
                return (int) DUMMY_BYTE;
        }
    }

    public void write(Integer value) {
        if (value == null) {
            throw new RuntimeException("St950x0.write(null)");
        }
        else {
            int byteValue = value & 0xFF;
            if (!selected) {
                throw new RuntimeException("St950x0.write(0x" + Format.asHex(byteValue & 0xFF, 2) + ") called while eeprom is not SELECTed !");
            }
            // Writing a value to serial eeprom means clock is ticking, so a value has to be transmitted back synchronously
            targetDevice.write(read());

            if (currentCommand == null) {
                // first byte is a new command
                switch (byteValue) {
                    case WREN:
                        setWriteLatchEnabled();
                        break;
                    case WRDI:
                        clearWriteLatchEnabled();
                        break;
                    case RDSR:
                        currentCommand = Command.RDSR;
                        break;
                    case WRSR:
                        currentCommand = Command.WRSR;
                        break;
                    case READ0:
                        currentCommand = Command.READ0;
                        break;
                    case READ1:
                        currentCommand = Command.READ1;
                        break;
                    case WRITE0:
                        currentCommand = Command.WRITE0;
                        break;
                    case WRITE1:
                        currentCommand = Command.WRITE1;
                        break;
                    default:
                        throw new RuntimeException("Unknown command : 0b" + Format.asBinary(byteValue, 8));
                }
            }
            else if (currentCommand == Command.READ0 || currentCommand == Command.READ1 || currentCommand == Command.WRITE0 || currentCommand == Command.WRITE1) {
                write1offset = 0x100;
                if (currentAddress == null) {
                    // "decode" 2nd byte as an address
                    if (currentCommand == Command.READ0 || currentCommand == Command.WRITE0) {
                        // Page 0
                        currentAddress = byteValue;
                    }
                    else {
                        // Page 1
                        currentAddress = write1offset | byteValue;
                    }
                }
                else {
                    // We have a READ/WRITE command and an address
                    // This is the "data phase"
                    switch (currentCommand) {
                        // If READ command, the value received is meaningless : ignore it
                        case READ0:
                        case READ1:
                            break;
                        // If WRITE command, store it at the corresponding address and increment address
                        case WRITE0:
                            // Write to page 0
                            performWrite(currentAddress, value);
                            // Prepare next read by incrementing address, wrapping at 16
                            currentAddress = (currentAddress & 0xFFFFFFF0) | ((currentAddress + 1) & 0xF);
                            break;
                        case WRITE1:
                            // Write to page 1
                            performWrite(write1offset | currentAddress, value);
                            // Prepare next read by incrementing address, wrapping at 16
                            currentAddress = (currentAddress & 0xFFFFFFF0) | ((currentAddress + 1) & 0xF);
                            break;
                    }
                }
            }
            else if (currentCommand == Command.RDSR) {
                // This is the "data phase". Ignore received byte
            }
            else if (currentCommand == Command.WRSR) {
                // This is the "data phase". Store the received value (only protection bytes are writeable)
                statusRegister = (statusRegister & 0b11110011) | (byteValue & 0b00001100);
            }
            else {
                System.err.println("Unimplemented command : " + currentCommand);
            }
        }
    }

    private void performWrite(int address, int value) {
        if (isWriteLatchEnabled() && !writeProtected && !isBlockProtected(address)) {
            memory[address] = (byte) value;
        }
    }

    private boolean isBlockProtected(int address) {
        int protectThreshold = Integer.MAX_VALUE;
        switch((statusRegister >> 2) & 0b11) {
            case 0b01: protectThreshold = memory.length * 3 / 4; break;
            case 0b10: protectThreshold = memory.length     / 2; break;
            case 0b11: protectThreshold = 0; break;
        }
        return address >= protectThreshold;
    }

    public int getNumBits() {
        return numBits;
    }

    @Override
    public void onBitNumberChange(SerialDevice serialDevice, int numBits) {
        this.numBits = numBits;
        System.out.println("St950x0.onBitNumberChange not implemented");
    }

    public String toString() {
        return name;
    }

}
