/*
 * Package : Cbor
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/12/2016
 * Copyright :  S.Hamblett
 */

part of cbor;

/// The encoder class implements the CBOR decoder functionality as defined in
/// RFC7049.

class Encoder {
  Output _out;

  Encoder(Output out) {
    this._out = out;
  }

  void clear() {
    _out.clear();
  }

  void _writeTypeValue(int majorType, int value) {
    int type = majorType;
    type <<= majorTypeShift;
    if (value < ai24) {
      // Value
      _out.putByte((type | value));
    } else if (value < two8) {
      // Uint8
      _out.putByte((type | ai24));
      _out.putByte(value);
    } else if (value < two16) {
      // Uint16
      _out.putByte((type | ai25));
      final typed.Uint16Buffer buff = new typed.Uint16Buffer(1);
      buff[0] = value;
      final Uint8List ulist = new Uint8List.view(buff.buffer);
      final typed.Uint8Buffer data = new typed.Uint8Buffer();
      data.addAll(ulist
          .toList()
          .reversed);
      _out.putBytes(data);
    } else if (value < two32) {
      // Uint32
      _out.putByte((type | ai26));
      final typed.Uint32Buffer buff = new typed.Uint32Buffer(1);
      buff[0] = value;
      final Uint8List ulist = new Uint8List.view(buff.buffer);
      final typed.Uint8Buffer data = new typed.Uint8Buffer();
      data.addAll(ulist
          .toList()
          .reversed);
      _out.putBytes(data);
    } else if (value < two64) {
      // Uint64
      _out.putByte((type | ai27));
      final typed.Uint64Buffer buff = new typed.Uint64Buffer(1);
      buff[0] = value;
      final Uint8List ulist = new Uint8List.view(buff.buffer);
      final typed.Uint8Buffer data = new typed.Uint8Buffer();
      data.addAll(ulist
          .toList()
          .reversed);
      _out.putBytes(data);
    } else {
      // Bignum - not supported, use tags
      print("Bignums not supported");
    }
  }

  void writeBool(bool value) {
    if (value) {
      _out.putByte(0xf5);
    } else {
      _out.putByte(0xf4);
    }
  }

  void writeInt(int value) {
    if (value < 0) {
      _writeTypeValue(1, -(value + 1));
    } else {
      _writeTypeValue(0, value);
    }
  }

  void writeBytes(typed.Uint8Buffer data) {
    _writeTypeValue(2, data.length);
    _out.putBytes(data);
  }

  void writeString(String str) {
    _writeTypeValue(3, str.length);
    final typed.Uint8Buffer buff = new typed.Uint8Buffer();
    str.codeUnits.forEach((int unit) {
      buff.add(unit);
    });
    _out.putBytes(buff);
  }

  void writeBuff(typed.Uint8Buffer data, int size) {
    _writeTypeValue(3, size);
    _out.putBytes(data);
  }

  void writeArray(int size) {
    _writeTypeValue(4, size);
  }

  void writeMap(int size) {
    _writeTypeValue(5, size);
  }

  void writeTag(int tag) {
    _writeTypeValue(6, tag);
  }

  void writeSpecial(int special) {
    int type = 7;
    type <<= majorTypeShift;
    _out.putByte(type | special);
  }

  void writeNull() {
    _out.putByte(0xf6);
  }

  void writeUndefined() {
    _out.putByte(0xf7);
  }

  void writeFloat(double value) {
    if (value <= halfLimit) {
      final typed.Uint8Buffer valBuff = _singleToHalf(value);
      writeSpecial(ai25);
      _out.putByte(valBuff[1]);
      _out.putByte(valBuff[0]);
    }
  }

  typed.Uint8Buffer _singleToHalf(double value) {
    final typed.Float32Buffer fBuff = new typed.Float32Buffer(1);
    fBuff[0] = value;
    final ByteBuffer bBuff = fBuff.buffer;
    final Uint8List uList = bBuff.asUint8List();
    final int intVal =
    uList[0] | uList[1] << 8 | uList[2] << 16 | uList[3] << 24;
    final int index = intVal >> 23;
    final int masked = intVal & 0x7FFFFF;
    final int hBits = baseTable[index] + ((masked) >> shiftTable[index]);
    final typed.Uint16Buffer hBuff = new typed.Uint16Buffer(1);
    hBuff[0] = hBits;
    final ByteBuffer lBuff = hBuff.buffer;
    final Uint8List hList = lBuff.asUint8List();
    final typed.Uint8Buffer valBuff = new typed.Uint8Buffer();
    valBuff.addAll(hList);
    return valBuff;
  }
}
