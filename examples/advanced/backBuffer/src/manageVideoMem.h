//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2017 Bouche Arnaud
//  Copyright (C) 2017 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//------------------------------------------------------------------------------

#ifndef _MANAGEVIDEOMEM_H_
#define _MANAGEVIDEOMEM_H_

#include <cpctelera.h>

////////////////////////////////////////////////////////////////////////////////////////////
// PUBLIC FUNCTION DECLARATIONS
//
void  FlipBuffer        ();
u8*   GetScreenPtr      (u8 xPos, u8 yPos);
u8*   GetBackBufferPtr  (u8 xPos, u8 yPos);
void  initVideoMemoryBuffers();

#endif