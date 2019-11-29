package wire

import (
    "encoding/binary"
    "io"
    "math"
)

func readBytes(r io.Reader) ([]byte, error) {
    length, err := readUint16(r)
    if err != nil { return nil, err }

    buf := make([]byte, length)
    _, err = io.ReadFull(r, buf)
    if err != nil { return nil, err }

    return buf, nil
}

func readFloat64(r io.Reader) (float64, error) {
    bits, err := readUint64(r)
    return math.Float64frombits(bits), err
}

func readUint8(r io.Reader) (uint8, error) {
    var buf [1]byte
    _, err := io.ReadFull(r, buf[:])
    if err != nil { return 0, err }

    return buf[0], err
}

func readUint16(r io.Reader) (uint16, error) {
    var buf [2]byte
    _, err := io.ReadFull(r, buf[:])
    if err != nil { return 0, err }

    val := binary.LittleEndian.Uint16(buf[:])
    return val, nil
}

func readUint64(r io.Reader) (uint64, error) {
    var buf [8]byte
    _, err := io.ReadFull(r, buf[:])
    if err != nil { return 0, err }

    val := binary.LittleEndian.Uint64(buf[:])
    return val, nil
}
