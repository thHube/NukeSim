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

-- Contains tasks and utility to manage control rods.
-- author  : Alberto Franco
package Control_Rods is

   -- Periodic checking task for control rods status
   task Control_Rods_Status;

   -- Associated control agent for sporadic task Control_Rods_Actuator
   protected Control_Rods_Actuator_Control_Agent is
      -- The sporadic task wait on this guarded entry
      entry Wait(Rods_Offset: out Float);
      -- This procedure unlocks the guarded entry
      procedure Notify(Rods_Offset:in Float);
   private
      Activate   : Boolean := False; -- Guard for the entry
      New_Height : Float   := 0.0;   -- New height to set to the control rods
   end Control_Rods_Actuator_Control_Agent;

   -- Sporadic task control rods actuator
   task Control_Rods_Actuator;

private

   -----------------------------------------------------------------------------
   -- Jobs
   -----------------------------------------------------------------------------
   procedure Check_Control_Rods;
   procedure Raise_Control_Rods(Rods_Height:in Float);

   -- Rods height hard limit
   RODS_SAFETY_HEIGHT: constant Float := 1000.0;
   RODS_SAFETY_LOWER : constant Float := -100.0;

   -----------------------------------------------------------------------------
   -- Scheduling data
   -----------------------------------------------------------------------------
   CONTROL_RODS_STATUS_PERIOD        : Time_Span := Milliseconds(500);
   CONTROL_RODS_ACTUATOR_INTERARRIVAL: Time_Span := Milliseconds(1000);

end Control_Rods;
