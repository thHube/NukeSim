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

package body Notification is

   -- Create a new status log message with the given message
   function Create_Status_Log(Msg: in Message_Notification) return Message is
      New_Message: Message;
   begin
      New_Message := (Msg_Type   => STATUS_LOG,
                     Msg_String => Msg,
                     New_Mode   => START_MODE );
      return New_Message;
   end Create_Status_Log;

   -- Create a mode change message to the given mode.
   function Create_Mode_Change(New_Mode: in Operation_Modes) return Message is
      New_Message: Message;
   begin
      New_Message := (Msg_Type   => MODE_CHANGE,
                     Msg_String => (Switch => RC_PUMP, Params => 0.0),
                     New_Mode   => New_Mode);
      return New_Message;
   end Create_Mode_Change;

   -- Control agent for notification pipe (implementation)
   protected body Notification_Pipe_Control_Agent is
      -- Guarded entry to activate sporadic task
      entry Wait(New_Message : out Message) when Activate is
      begin
         New_Message := Message_To_Deliver;
         Activate := False;
      end Wait;

      -- Procedure to trigger sporadic task
      procedure Notify(New_Message:in Message) is
      begin
         Message_To_Deliver := New_Message;
         Activate := True;
      end Notify;

   end Notification_Pipe_Control_Agent;

   -- Notification pipe task implementation
   task body Notification_Pipe is
      Next_Activation : Time := Start_Time;
      Current_Message : Message;
   begin
      Start_Deamon.Wait_For_System_Start;
      loop
         delay until Next_Activation;
         Notification_Pipe_Control_Agent.wait(New_Message => Current_Message);

         Next_Activation := Clock + NOTIFICATION_PIPE_INTERARRIVAL;
         Dispatch_Message(Current_Message);
      end loop;
   end Notification_Pipe;

   -- Job for notification pipe.
   procedure Dispatch_Message(Msg: in Message) is
   begin
      case Msg.Msg_Type is
         when STATUS_LOG  =>
            Log_manager.Log_String(Msg.Msg_String);
         when MODE_CHANGE =>
            Mode_Changer.Switch_To(Msg.New_Mode);
            Put_Line("[MODE CHANGER]: Changed mode to " & Msg.New_Mode'Img);
      end case;
   end Dispatch_Message;

   -- Implementation of log manager protected resource.
   protected body Log_Manager is
      procedure Log_String (Msg: in Message_Notification) is
         Str          : Unbounded_String;
      begin
         case Msg.Switch is
            when RC_PUMP =>
               Str := To_Unbounded_String("[RC PUMP     ]: Flow level " & Msg.Params'Img);
            when RC_CONTROL_RODS =>
               Str := To_Unbounded_String("[CONTROL RODS]: Moving " & Msg.Params'Img);
            when COOLING_SYSTEM =>
               Str := To_Unbounded_String("[COOLING SYS ]: Failure, current status " & Msg.Params'Img);
            when TC_PUMP =>
               Str := To_Unbounded_String("[TC PUMP     ]: Flow level " & Msg.Params'Img);
            when RC_PRESSURE =>
               Str := To_Unbounded_String("[RC PRESSURE ]: Change pressure to " & Msg.Params'Img);
            when OUTPUT_PWR =>
               Str := To_Unbounded_String("[OUTPUT POWER]: Could not raise output power");
         end case;
         Put_Line(To_String(Str));
         Log := Log & Str;
      end Log_String;
   end Log_Manager;

end Notification;