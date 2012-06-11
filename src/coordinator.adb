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

-- author  : Alberto Franco
package body Coordinator is

   -- Sporadic task Mode_Changer implementation
   task body Mode_Changer_Daemon is
      Next_Activation : Time := Start_Time;
      Release_Time    : Time;
   begin
      Start_Deamon.Wait_For_System_Start;
      loop
         delay until Next_Activation;
         Release_Time := Clock;
         Mode_Changer.Mode_Has_Changed;
         Change_Operation_Mode(Mode_Changer.Get_Current_Mode);
         Next_Activation := Release_Time + MODE_CHANGER_INTERARRIVAL;
      end loop;
   end Mode_Changer_Daemon;

   -- Start_Daemon implementation
   protected body Start_Deamon is
      entry Wait_For_System_Start when Is_Waiting is
      begin null; end;

      procedure Awake_System(The_Delay: in Time_Span) is
      begin
         Start_Time := Clock + The_Delay;
         Is_Waiting := False;
      end Awake_System;

   end Start_Deamon;

   -- Mode changer protected resource.
   protected body Mode_Changer is
      -- Guarded entries for ATC
      entry Goto_Maintainance_Mode when Is_Maintainance is
      begin null; end Goto_Maintainance_Mode;

      entry Restart_Operations when not Is_Maintainance is
      begin null; end Restart_Operations;

      -- Guarded entry for mode changer sporadic task.
      entry Mode_Has_Changed when Issued_Mode_Change is
      begin
         Issued_Mode_Change := False;
      end Mode_Has_Changed;

      -- Mode changer switch procedure
      procedure Switch_To(Mode: in Operation_Modes) is
      begin
         Current_Mode       := Mode;
         Issued_Mode_Change := True;
      end Switch_To;

      -- Current mode getter
      function Get_Current_Mode return Operation_Modes is
      begin
         return Current_Mode;
      end Get_Current_Mode;

      -- Triggers ATC for abortable task
      procedure Undergo_Maintainance is
      begin
         Is_Maintainance := True;
      end Undergo_Maintainance;

      -- Restart abortable task
      procedure Start_Operations is
      begin
         Is_Maintainance := False;
      end Start_Operations;
   end Mode_Changer;

   -- Job issued by Mode_Changer_Daemon.
   procedure Change_Operation_Mode(Mode:in Operation_Modes) is
   begin
      case Mode is
         when START_MODE =>
            Mode_Changer.Start_Operations;
         when MAINTAINANCE_MODE =>
            Mode_Changer.Undergo_Maintainance;
      end case;
   end Change_Operation_Mode;

end Coordinator;
