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
with Coordinator;       use Coordinator;
with Plant_Simulator;   use Plant_Simulator;
with Notification;      use Notification;

-- Control rods management package. Contains both periodic and sporadic tasks.
-- author: Alberto Franco
package body Control_Rods is

   -- Control_Rods_Status task implementation
   task body Control_Rods_Status is
      Next_Activation:Time := Start_Time;
   begin
      loop
         -- This task is active all of the time.
         delay until Next_Activation;
         Next_Activation := CONTROL_RODS_STATUS_PERIOD + Clock;
         Check_Control_Rods;
      end loop;
   end Control_Rods_Status;

   -- Protected resource that manages control_rods_actuator.
   protected body Control_Rods_Actuator_Control_Agent is
      -- Waits for the guard to open up and activate the sporadic task
      entry Wait(Rods_Offset: out Float ) when Activate is
      begin
         Rods_Offset := New_Height;
         Activate := False;
      end Wait;

      -- Notifies the sporadic task to start.
      procedure Notify(Rods_Offset: in Float) is
      begin
         New_Height := New_Height + Rods_Offset;
         Activate   := True;
      end Notify;
   end Control_Rods_Actuator_Control_Agent;

   -- Implementation of the sporadic task control rods actuator.
   task body Control_Rods_Actuator is
      Next_Activation : Time := Start_Time;
      New_Height      : Float;
   begin
      loop
         delay until Next_Activation;
         Control_Rods_Actuator_Control_Agent.Wait(Rods_Offset => New_Height);

         Next_Activation := Clock + CONTROL_RODS_ACTUATOR_INTERARRIVAL;
         Raise_Control_Rods(New_Height);
      end loop;
   end Control_Rods_Actuator;

   -----------------------------------------------------------------------------
   -- Jobs implementation
   -----------------------------------------------------------------------------

   -- Implementation of the job that checks for control rods height
   procedure Check_Control_Rods is
      Current_Height   : constant Float := Plant.Get_Rods_Height;
   begin
      if Current_Height > RODS_SAFETY_HEIGHT then
         Control_Rods_Actuator_Control_Agent.Notify(RODS_SAFETY_LOWER);
      end if;
   end Check_Control_Rods;

   -- This job raise the control rods up to the given height.
   procedure Raise_Control_Rods(Rods_Height:in Float) is
      Msg_Notification : constant Message_Notification :=
        (RC_CONTROL_RODS, Rods_Height);
   begin
      Plant.Raise_Control_Rods(Rods_Height => Rods_Height);
      Notification_Pipe_Control_Agent.Notify(Create_Status_Log(Msg_Notification));
   end Raise_Control_Rods;

end Control_Rods;

