#ifndef BSNESCORE_HPP
#define BSNESCORE_HPP

#include <stdint.h>
#include <stdlib.h>

#define EXPORT ECL_EXPORT

#define SAMPLE_RATE 32040

enum SNES_MEMORY {
    CARTRIDGE_RAM,
    CARTRIDGE_ROM,
    SGB_ROM,

    // bsx and sufamiturbo unused cause unsupported by frontend
    BSX_RAM,
    BSX_PRAM,
    SUFAMI_TURBO_A_RAM,
    SUFAMI_TURBO_B_RAM,
    SA1_IRAM,
    SA1_BWRAM,

    WRAM,
    APURAM,
    VRAM,
    CGRAM
};


struct LayerEnables
{
    bool BG1_Prio0, BG1_Prio1;
    bool BG2_Prio0, BG2_Prio1;
    bool BG3_Prio0, BG3_Prio1;
    bool BG4_Prio0, BG4_Prio1;
    bool Obj_Prio0, Obj_Prio1, Obj_Prio2, Obj_Prio3;
};

struct SnesRegisters
{
    uint32_t pc;
    uint16_t a, x, y, z, s, d;
    uint8_t b, p, mdr;
    bool e;
    uint16_t v, h;
};


// below code unused; would be useful for the graphics debugger
//$2105
#define SNES_REG_BG_MODE 0
#define SNES_REG_BG3_PRIORITY 1
#define SNES_REG_BG1_TILESIZE 2
#define SNES_REG_BG2_TILESIZE 3
#define SNES_REG_BG3_TILESIZE 4
#define SNES_REG_BG4_TILESIZE 5
//$2107
#define SNES_REG_BG1_SCADDR 10
#define SNES_REG_BG1_SCSIZE 11
//$2108
#define SNES_REG_BG2_SCADDR 12
#define SNES_REG_BG2_SCSIZE 13
//$2109
#define SNES_REG_BG3_SCADDR 14
#define SNES_REG_BG3_SCSIZE 15
//$210A
#define SNES_REG_BG4_SCADDR 16
#define SNES_REG_BG4_SCSIZE 17
//$210B
#define SNES_REG_BG1_TDADDR 20
#define SNES_REG_BG2_TDADDR 21
//$210C
#define SNES_REG_BG3_TDADDR 22
#define SNES_REG_BG4_TDADDR 23
//$2133 SETINI
#define SNES_REG_SETINI_MODE7_EXTBG 30
#define SNES_REG_SETINI_HIRES 31
#define SNES_REG_SETINI_OVERSCAN 32
#define SNES_REG_SETINI_OBJ_INTERLACE 33
#define SNES_REG_SETINI_SCREEN_INTERLACE 34
//$2130 CGWSEL
#define SNES_REG_CGWSEL_COLORMASK 40
#define SNES_REG_CGWSEL_COLORSUBMASK 41
#define SNES_REG_CGWSEL_ADDSUBMODE 42
#define SNES_REG_CGWSEL_DIRECTCOLOR 43
//$2101 OBSEL
#define SNES_REG_OBSEL_NAMEBASE 50
#define SNES_REG_OBSEL_NAMESEL 51
#define SNES_REG_OBSEL_SIZE 52
//$2131 CGADSUB
#define SNES_REG_CGADDSUB_MODE 60
#define SNES_REG_CGADDSUB_HALF 61
#define SNES_REG_CGADDSUB_BG4 62
#define SNES_REG_CGADDSUB_BG3 63
#define SNES_REG_CGADDSUB_BG2 64
#define SNES_REG_CGADDSUB_BG1 65
#define SNES_REG_CGADDSUB_OBJ 66
#define SNES_REG_CGADDSUB_BACKDROP 67
//$212C TM
#define SNES_REG_TM_BG1 70
#define SNES_REG_TM_BG2 71
#define SNES_REG_TM_BG3 72
#define SNES_REG_TM_BG4 73
#define SNES_REG_TM_OBJ 74
//$212D TM
#define SNES_REG_TS_BG1 80
#define SNES_REG_TS_BG2 81
#define SNES_REG_TS_BG3 82
#define SNES_REG_TS_BG4 83
#define SNES_REG_TS_OBJ 84
//Mode7 regs
#define SNES_REG_M7SEL_REPEAT 90
#define SNES_REG_M7SEL_HFLIP 91
#define SNES_REG_M7SEL_VFLIP 92
#define SNES_REG_M7A 93
#define SNES_REG_M7B 94
#define SNES_REG_M7C 95
#define SNES_REG_M7D 96
#define SNES_REG_M7X 97
#define SNES_REG_M7Y 98
//BG scroll regs
#define SNES_REG_BG1HOFS 100
#define SNES_REG_BG1VOFS 101
#define SNES_REG_BG2HOFS 102
#define SNES_REG_BG2VOFS 103
#define SNES_REG_BG3HOFS 104
#define SNES_REG_BG3VOFS 105
#define SNES_REG_BG4HOFS 106
#define SNES_REG_BG4VOFS 107
#define SNES_REG_M7HOFS 108
#define SNES_REG_M7VOFS 109


int snes_peek_logical_register(int reg);


#endif
