
float8 :: struct {
    f0, f1, f2, f3, f4, f5, f6, f7: float;
    
#place f0;
    F: [8] float;
}

operator [] :: (V: float8, Index: int) -> float {
    return V.F[Index];
}

operator []= :: (V: *float8, Index: int, Value: float) {
    V.F[Index] = Value;
}

PackFloat8 :: (f: float) -> float8 {
    Result: float8;
    for 0..7 Result.F[it] = f;
    return Result;
}

PackFloat8 :: (f: [8] float) -> float8 {
    Result: float8;
    for 0..7 Result.F[it] = f[it];
    return Result;
}

int32x8 :: struct {
    i0, i1, i2, i3, i4, i5, i6, i7: s32;
    
#place i0;
    I: [8] s32;
}

operator [] :: (V: int32x8, Index: int) -> s32 {
    return V.I[Index];
}

PackInt8 :: (i: s32) -> int32x8 {
    Result: int32x8;
    for 0..7 Result.I[it] = i;
    return Result;
}

PackInt8 :: (i: [8] s32) -> int32x8 {
    Result: int32x8;
    for 0..7 Result.I[it] = i[it];
    return Result;
}

Dot8 :: (Ax: reg, Ay: reg, Az: reg, Bx: reg, By: reg, Bz: reg, r: reg) #expand {
#asm {
        movaps a:, Ax;
        mulps a, a, Bx; // a = Ax*Bx
        
        movaps r, a; // r = a
        
        movaps a, Ay;
        mulps a, a, By; // a = Ay*By
        addps r, r, a; // r += a
        
        movaps a, Az;
        mulps a, a, Bz;  // a = Az*Bz
        addps r, r, a; // r += a
    }
}

Cross8 :: (Ax: reg, Ay: reg, Az: reg, Bx: reg, By: reg, Bz: reg, rx: reg, ry: reg, rz: reg) #expand {
#asm {
        // rx = Ay * Bz - Az * By
        movaps a:, Ay;
        mulps a, a, Bz;  // a = Ay * Bz
        movaps b:, Az;
        mulps b, b, By;  // b = Az * By
        subps a, a, b;   // a = a - b
        movaps rx, a;    // rx = a
        
        // ry = Az * Bx - Ax * Bz
        movaps a, Az;
        mulps a, a, Bx;  // a = Az * Bx
        movaps b, Ax;
        mulps b, b, Bz;  // b = Ax * Bz
        subps a, a, b;   // a = a - b
        movaps ry, a;    // ry = a
        
        // rz = Ax * By - Ay * Bx
        movaps a, Ax;
        mulps a, a, By;  // a = Ax * By
        movaps b, Ay;
        mulps b, b, Bx;  // b = Ay * Bx
        subps a, a, b;   // a = a - b
        movaps rz, a;    // rz = a
    }
}

_CMP_EQ_OQ    :u8: 0x00; /* Equal (ordered, non-signaling)  */
_CMP_LT_OS    :u8: 0x01; /* Less-than (ordered, signaling)  */
_CMP_LE_OS    :u8: 0x02; /* Less-than-or-equal (ordered, signaling)  */
_CMP_UNORD_Q  :u8: 0x03; /* Unordered (non-signaling)  */
_CMP_NEQ_UQ   :u8: 0x04; /* Not-equal (unordered, non-signaling)  */
_CMP_NLT_US   :u8: 0x05; /* Not-less-than (unordered, signaling)  */
_CMP_NLE_US   :u8: 0x06; /* Not-less-than-or-equal (unordered, signaling)  */
_CMP_ORD_Q    :u8: 0x07; /* Ordered (non-signaling)   */
_CMP_EQ_UQ    :u8: 0x08; /* Equal (unordered, non-signaling)  */
_CMP_NGE_US   :u8: 0x09; /* Not-greater-than-or-equal (unordered, signaling)  */
_CMP_NGT_US   :u8: 0x0a; /* Not-greater-than (unordered, signaling)  */
_CMP_FALSE_OQ :u8: 0x0b; /* False (ordered, non-signaling)  */
_CMP_NEQ_OQ   :u8: 0x0c; /* Not-equal (ordered, non-signaling)  */
_CMP_GE_OS    :u8: 0x0d; /* Greater-than-or-equal (ordered, signaling)  */
_CMP_GT_OS    :u8: 0x0e; /* Greater-than (ordered, signaling)  */
_CMP_TRUE_UQ  :u8: 0x0f; /* True (unordered, non-signaling)  */
_CMP_EQ_OS    :u8: 0x10; /* Equal (ordered, signaling)  */
_CMP_LT_OQ    :u8: 0x11; /* Less-than (ordered, non-signaling)  */
_CMP_LE_OQ    :u8: 0x12; /* Less-than-or-equal (ordered, non-signaling)  */
_CMP_UNORD_S  :u8: 0x13; /* Unordered (signaling)  */
_CMP_NEQ_US   :u8: 0x14; /* Not-equal (unordered, signaling)  */
_CMP_NLT_UQ   :u8: 0x15; /* Not-less-than (unordered, non-signaling)  */
_CMP_NLE_UQ   :u8: 0x16; /* Not-less-than-or-equal (unordered, non-signaling)  */
_CMP_ORD_S    :u8: 0x17; /* Ordered (signaling)  */
_CMP_EQ_US    :u8: 0x18; /* Equal (unordered, signaling)  */
_CMP_NGE_UQ   :u8: 0x19; /* Not-greater-than-or-equal (unordered, non-signaling)  */
_CMP_NGT_UQ   :u8: 0x1a; /* Not-greater-than (unordered, non-signaling)  */
_CMP_FALSE_OS :u8: 0x1b; /* False (ordered, signaling)  */
_CMP_NEQ_OS   :u8: 0x1c; /* Not-equal (ordered, signaling)  */
_CMP_GE_OQ    :u8: 0x1d; /* Greater-than-or-equal (ordered, non-signaling)  */
_CMP_GT_OQ    :u8: 0x1e; /* Greater-than (ordered, non-signaling)  */
_CMP_TRUE_US  :u8: 0x1f; /* True (unordered, signaling)  */

#scope_file

reg :: __reg;