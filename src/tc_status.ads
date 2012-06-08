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
with Ada.Real_Time; use Ada.Real_Time;

package TC_Status is

   -- Periodic task for heat exchange checks
   task Heat_Exchange_Temp_Status;

   -- Periodic task for checking the TC pump
   task TC_Pump_Status;

   -- Periodic task for checking cooling system
   task Cooling_System_Status;

private

   -- Scheduling parameters
   HEAT_EXCHANGE_TEMP_STATUS_PERIOD: Time_Span := Milliseconds(700);
   TC_PUMP_STATUS_PERIOD           : Time_Span := Milliseconds(700);
   COOLING_SYSTEM_STATUS_PERIOD    : Time_Span := Milliseconds(700);

   -----------------------------------------------------------------------------
   -- Jobs declaration
   -----------------------------------------------------------------------------
   procedure Check_Heat_Exchange_Temperature;
   procedure Check_TC_Pump_Operation;
   procedure Check_Cooling_System;

end TC_Status;
