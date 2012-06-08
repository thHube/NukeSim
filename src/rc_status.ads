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

package RC_Status is

   -- Periodic task for water temperature checking
   task Water_Temperature_Status;

   -- Periodic task for RC Pump check
   task RC_Pump_Status;

   -- Sporadic actuator task for RC pressure
   task RC_Pressure_Actuator;

   -- Protected resource to manage RC_Pressure_Actuator periodic task
   protected RC_Pressure_Actuator_Control_Agent is
      entry Wait(Pressure: out Float);
      procedure Notify(New_Pressure: in Float);

   private
      Activate: Boolean := False;
      Current_Pressure: Float;
   end RC_Pressure_Actuator_Control_Agent;

private
   -- Scheduling data.
   WATER_TEMPERATURE_STATUS_PERIOD  : Time_Span := Milliseconds(350);
   RC_PUMP_STATUS_PERIOD            : Time_Span := Milliseconds(350);
   RC_PRESSURE_ACTUATOR_INTERARRIVAL: Time_Span := Milliseconds(600);

   -- Constant data pressure is in MPa
   WATER_TEMPERTATURE_LOWER : constant Float := 150.0;
   WATER_BOIL_SAFE_LIMIT    : constant Float := 20.0;
   WATER_BOIL_RODS_LOWER    : constant Float := -250.0;
   WATER_BOIL_PRESSURE_HIGH : constant Float := 10.0;
   PRESSURE_SAFE_LIMIT      : constant Float := 100.0;
   -----------------------------------------------------------------------------
   -- Jobs
   -----------------------------------------------------------------------------
   procedure Check_Water_Pressure_And_Temp;
   procedure Check_RC_Pump_Operations;
   procedure Change_RC_Pressure_To(New_Pressure:Float);

end RC_Status;
