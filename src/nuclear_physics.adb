--------------------------------------------------------------------------------
-- NukeSim, a nuclear plant real-time simulation for educational purpose      --
-- Copyright (C) 2012  Alberto Franco                                         --
--                                                                            --
-- This program is free software: you can redistribute it and/or modify       --
-- it under the terms of the GNU General Public License as published by       --
-- the Free Software Foundation, either version 3 of the License, or          --
-- (at your option) any later version.                                        --
--                                                                            --
-- This program is distributed in the hope that it will be useful,            --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of             --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              --
-- GNU General Public License for more details.                               --
--                                                                            --
-- You should have received a copy of the GNU General Public License          --
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.      --
--------------------------------------------------------------------------------
with Ada.Numerics.Generic_Elementary_Functions;

with Ada.Text_IO; use Ada.Text_IO;

-- Implementation of the Nuclear_Physics package. This package contains utility
-- functions that are related to physics.
-- author: Alberto Franco
package body Nuclear_Physics is

   -- Renaming of the generic elementary math package to use Log() function
   package Math is new Ada.Numerics.Generic_Elementary_Functions (Float);

   -- Return water boiling point at the given pressure. The calculation is
   -- derived from the ideal gas equation. Pressure is in MPa and temperature
   -- in Kelvin. 1 / T =  0.002475 * ln( P / 10.1325 )
   function Get_Water_Boiling_Point(Pressure: Float) return Float is
      INVERSE_CONST : constant Float := 404.040404;
      PRESSURE_SEA  : constant Float := 0.0986923267;
      Inverse_Log   : constant Float := 1.0 / Math.Log(Pressure * PRESSURE_SEA);
   begin
      return INVERSE_CONST * Inverse_Log;
   end Get_Water_Boiling_Point;

   -- Implementation of the function to get the temperature given the current
   -- reactor circuit configuration. This correlation is not exact since the
   -- relation between rods immersion and energy emitted is highly non-linear
   function Get_RC_Temperature(Conf:RC_Configuration) return Float is
      Temperature: Float;
   begin
      Temperature := Conf.Rods_Height * Rods_Height_Factor;
      return Temperature;
   end Get_RC_Temperature;

   -- Implementation of the function to get the turbine circuit temperature
   -- at heat exchange.
   function Get_TC_Temperature(Conf:TC_Configuration) return Float is
      Delta_Temperature: Float;
      Delta_Pressure   : Float := Conf.RC_Conf.RC_Water_Pressure - Reference_Pressure;
   begin
      Delta_Temperature := (TC_Pipe_Flow * Water_Enthalpy_Vapo) -
        (RC_Pipe_Flow * Delta_Pressure * 1.002);
      Delta_Temperature := Delta_Temperature / (RC_Pipe_Flow * Water_Heat_Capacity);
      return Delta_Temperature;
   end Get_TC_Temperature;

   -- Returns the output power in percentage from the given configuration. This
   -- perfoms a very simple calculation returning the ratio between the actual
   -- temperature of the RC water and the heat exchanged.
   function Get_Output_Performance(Conf:TC_Configuration) return Float is
      Temp_Exchanged : Float := Get_TC_Temperature(Conf);
      Temp_RC        : Float := Get_RC_Temperature(Conf.RC_Conf);
   begin
      Put_Line("Temp_RC:" & Temp_RC'Img & ", Temp_Exchanged:" & Temp_Exchanged'Img);
      return  Temp_Exchanged / Temp_RC;
   end Get_Output_Performance;

end Nuclear_Physics;
