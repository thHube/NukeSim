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

-- This package manages tasks and resources that manage output power levels.
-- These objects are alive only in START_MODE, they are aborted on mode change.
-- author: Alberto Franco
package Output_Power is

   -- Periodic task to check for output power oscillations. This task is
   -- abortable. It uses ATC to manage abortion.
   task Output_Power_Status;

   -- Sporadic task that actuate output power raise. This task is alive only
   -- when Output_Power_Status is alive since it is the only task that triggers
   -- it.
   task Output_Power_Controller;

   -- Protected resource that manages Output_Power_Controller. This resource
   -- implements event-triggering for the sporadic task.
   protected Output_Power_Controller_Control_Agent is
      -- Wait returns the new power level to actuate
      entry Wait(New_Power_Level:out Float);
      -- Notify accept the new output power level
      procedure Notify(New_Power_Level:in Float);
   private
      Activate:Boolean := False;
      Power_Level:Float;
   end Output_Power_Controller_Control_Agent;

private

   -----------------------------------------------------------------------------
   -- Scheduling data.
   -----------------------------------------------------------------------------
   OUTPUT_POWER_STATUS_PERIOD          : Time_Span := Milliseconds(700);
   OUTPUT_POWER_CONTROLLER_INTERARRIVAL: Time_Span := Seconds(1);

   -----------------------------------------------------------------------------
   -- Jobs declaration
   -----------------------------------------------------------------------------
   procedure Check_Output_Power;
   procedure Raise_Output_Power;

end Output_Power;
