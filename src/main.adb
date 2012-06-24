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
with Ada.Text_IO; use Ada.Text_IO;

-- Import packages in order to start tasks.
with Control_Rods;      use Control_Rods;
with RC_Status;         use RC_Status;
with TC_Status;         use TC_Status;
with Output_Power;      use Output_Power;
with Plant_Simulator;   use Plant_Simulator;
with Notification;      use Notification;
with Coordinator;       use Coordinator;

with Ada.Command_Line;  use Ada.Command_Line;

-- Program entry point.
procedure Main is

begin
   Put_Line("NukeSim  Copyright (C) 2012  Alberto Franco");
   Put_Line("This program comes with ABSOLUTELY NO WARRANTY; for details see LICENSE.txt .");
   Put_Line("This is free software, and you are welcome to redistribute it");
   Put_Line("under conditions established by the license.");

   if Argument_Count < 1 then
      -- Error and abort all active tasks
      Put_Line(">> You must declare which configuration file you want to run.");
      -- Abort periodic tasks
      abort Control_Rods_Status;
      abort Water_Temperature_Status;
      abort RC_Pump_Status;
      abort Heat_Exchange_Temp_Status;
      abort TC_Pump_Status;
      abort Cooling_System_Status;
      abort Output_Power_Status;
      -- Abort sporadic task
      abort Output_Power_Controller;
      abort Control_Rods_Actuator;
      abort RC_Pressure_Actuator;
      abort Notification_Pipe;
      abort Mode_Changer_Daemon;

      Kill_Simulation;
      Set_Exit_Status(1);
   else
      -- Start the simulation with the given configuration file.
      Trigger_Simulation(Argument(1));
   end if;
end Main;
