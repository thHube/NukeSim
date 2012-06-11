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
with Coordinator;      use Coordinator;
with Nuclear_Physics;  use Nuclear_Physics;
with Control_Rods;     use Control_Rods;
with Plant_Simulator;  use Plant_Simulator;
with Ada.Text_IO;      use Ada.Text_IO;
with Notification;     use Notification;

-- author: Alberto Franco
package body Output_Power is

   -- Periodic task to check for output power oscillations. This task is
   -- abortable. It uses ATC to manage abortion.
   task body Output_Power_Status is
      Next_Activation:Time := Start_Time;
   begin
      Start_Deamon.Wait_For_System_Start;
      select
         Mode_Changer.Goto_Maintainance_Mode;
         Put_Line("[MODE CHANGER]: Abort Output_Power_Status");
         Mode_Changer.Restart_Operations;
      then abort
         loop
            delay until Next_Activation;
            Next_Activation := Clock + OUTPUT_POWER_STATUS_PERIOD;
            Check_Output_Power;
         end loop;
      end select;
   end Output_Power_Status;

   -- Sporadic task that actuate output power raise. This task is alive only
   -- when Output_Power_Status is alive since it is the only task that triggers
   -- it.
   task body Output_Power_Controller is
      Next_Activation : Time := Start_Time;
      Power_Level     : Float;
   begin
      Start_Deamon.Wait_For_System_Start;
      loop
         delay until Next_Activation;
         Output_Power_Controller_Control_Agent.Wait(New_Power_Level => Power_Level);

         Next_Activation := Clock + OUTPUT_POWER_CONTROLLER_INTERARRIVAL;
         Raise_Output_Power;
      end loop;
   end Output_Power_Controller;


   -- Protected resource that manages Output_Power_Controller. This resource
   -- implements event-triggering for the sporadic task.
   protected body Output_Power_Controller_Control_Agent is
      -- Wait returns the new power level to actuate
      entry Wait(New_Power_Level:out Float) when Activate is
      begin
         New_Power_Level := Power_level;
         Activate        := False;
      end Wait;

      -- Notify accept the new output power level
      procedure Notify(New_Power_Level:in Float) is
      begin
         Power_Level := New_Power_Level;
         Activate    := True;
      end Notify;
   end Output_Power_Controller_Control_Agent;

   -----------------------------------------------------------------------------
   -- Job implementation
   -----------------------------------------------------------------------------

   -- This job checks if the output power is above the given limit and, if not,
   -- raise of the given amount performances.
   procedure Check_Output_Power is
      PERFORMANCE_LIMIT : constant Float := 0.3;
      PERFORMANCE_OFFSET: constant Float := 10.0;
      Output_Performance: constant Float :=
                  Get_Output_Performance(Plant.Get_TC_Configuration);
   begin
      -- DEBUG PRINTS
      -- Put_Line("Output_Per" & Output_Performance'Img);
      -- Put_Line("Rods_height" & Plant.Get_Rods_Height'Img);
      if Output_Performance < PERFORMANCE_LIMIT then
         Output_Raise_Try_Count := Output_Raise_Try_Count + 1;
         Output_Power_Controller_Control_Agent.Notify(PERFORMANCE_LIMIT + PERFORMANCE_OFFSET);
      else
         Output_Raise_Try_Count := 0;
      end if;
   end Check_Output_Power;

   -- This procedure higher control rods in order to achieve an output power
   -- raise. It continues to higher rods until an hard limit is hit. If that
   -- limit is hit notifies the failure of the operation and change mode
   procedure Raise_Output_Power is
      RODS_HIGH_FACTOR : constant Float   := 100.0;
      TRY_HARD_LIMIT   : constant Integer := 20;
      Msg              : constant Message_Notification := (OUTPUT_PWR, 20.0);
   begin
      if Output_Raise_Try_Count < TRY_HARD_LIMIT then
         Control_Rods_Actuator_Control_Agent.Notify(Rods_Offset => RODS_HIGH_FACTOR);
      else
         Notification_Pipe_Control_Agent.Notify(Create_Status_Log(Msg));
         Mode_Changer.Switch_To(MAINTAINANCE_MODE);
      end if;
   end Raise_Output_Power;

end Output_Power;