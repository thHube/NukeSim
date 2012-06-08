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

package Nuclear_Physics is

   -----------------------------------------------------------------------------
   -- Constants
   -----------------------------------------------------------------------------
   RC_Pipe_Flow: constant Float := 23562.0;  -- In kg/s
   TC_Pipe_Flow: constant Float := 5890.5; -- In kg/s

   Water_Heat_Capacity: constant Float := 1.0;
   Water_Enthalpy_Vapo: constant Float := 731.808; -- in KJ/kg
   -----------------------------------------------------------------------------
   -- Functions
   -----------------------------------------------------------------------------

   -- Return water boiling point
   function Get_Water_Boiling_Point(Pressure: Float) return Float;

   -- Reactor cirtcuit configuration
   type RC_Configuration is
      record
         Rods_Height: Float;
         RC_Water_Pressure:Float;
      end record;

   -- Returns water temperature for RC from a configuration
   function Get_RC_Temperature(Conf:RC_Configuration) return Float;

   -- Turbine circuit configuration
   type TC_Configuration is
      record
         RC_Conf: RC_Configuration;
         TC_Water_Pressure:Float;
      end record;

   -- Get TC temperature from current configuration
   function Get_TC_Temperature(Conf:TC_Configuration) return Float;

   -- Returns output power from current configuration
   function Get_Output_Performance(Conf:TC_Configuration) return Float;

private
   -- Attenuation factor for rods height (max temp = 500 Celsius)
   Rods_Height_Factor: constant Float := 0.5;

   -- Reference pressure for enthalpy calculation
   Reference_Pressure: constant Float := 0.00234;

end Nuclear_Physics;