package wire

import "io"

type Event struct {
    Metric  float64
    Class   []byte
    Payload []byte
}

func ReadEvent(r io.Reader) (*Event, error) {
    metric, err := readFloat64(r)
    if err != nil { return nil, err }

    class, err := readBytes(r)
    if err != nil { return nil, err }

    payload, err := readBytes(r)
    if err != nil { return nil, err }

    event := &Event{metric, class, payload}
    return event, nil
}
