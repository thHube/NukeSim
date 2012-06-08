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

-- Coordinate tasks between operation modes and starting
-- author  : Alberto Franco
package Coordinator is

   -- Boot load times
   BOOTSTRAP_TIME: constant Time_Span := Seconds(2);
   BOOT_DELAY:     constant Time_Span := Milliseconds(200);

   -- Wait for system to load before starting operations
   Start_Time: Time := Clock + BOOTSTRAP_TIME + BOOT_DELAY;

   -- Type for mode management
   type Operation_Modes is (START_MODE, MAINTAINANCE_MODE);

   -- Mode changer daemon manages modes and tasks
   task Mode_Changer_Daemon;

   protected Mode_Changer is
      -- Manages maintainance mode for abortable tasks .
      entry Goto_Maintainance_Mode;
      entry Restart_Operations;

      -- manages mode change issue
      entry Mode_Has_Changed;
      -- Switch operation mode.
      procedure Switch_To(Mode:in Operation_Modes);
      -- Getter for current mode
      function Get_Current_Mode return Operation_Modes;
      -- Switch to maintainance and to start operations
      procedure Undergo_Maintainance;
      procedure Start_Operations;
   private
      Current_Mode       : Operation_Modes;
      Is_Maintainance    : Boolean := False;
      Issued_Mode_Change : Boolean := False;
   end Mode_Changer;

private

   MODE_CHANGER_INTERARRIVAL : Time_Span := Seconds(1);

   -- Mode_Changer_Daemon job
   procedure Change_Operation_Mode(Mode:in Operation_Modes);

end Coordinator;
