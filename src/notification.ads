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
with Coordinator;           use Coordinator;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Real_Time;         use Ada.Real_Time;

package Notification is

   -- Message type
   type Message_Type   is (MODE_CHANGE, STATUS_LOG);

   type Notification_Switch is
     (RC_PUMP, RC_PRESSURE, RC_CONTROL_RODS, COOLING_SYSTEM, TC_PUMP, OUTPUT_PWR);

   type Message_Notification is
      record
         Switch : Notification_Switch;
         Params : Float;
      end record;

   -- A full message.
   type Message is
      record
         Msg_Type   : Message_Type;
         Msg_String : Message_Notification;
         New_Mode   : Operation_Modes;
      end record;

   -- Sporadic task notification pipe
   task Notification_Pipe;

   -- Create a status log message.
   function Create_Status_Log(Msg: in Message_Notification) return Message;

   -- Create a mode change message.
   function Create_Mode_Change(New_Mode: in Operation_Modes) return Message;

   -- Control agent for notification pipe
   protected Notification_Pipe_Control_Agent is
      entry Wait(New_Message : out Message);
      procedure Notify(New_Message:in Message);
   private
      Activate : Boolean := False;
      Message_To_Deliver: Message;
   end Notification_Pipe_Control_Agent;

private
   -- Scheduluing data
   NOTIFICATION_PIPE_INTERARRIVAL : Time_Span := Milliseconds(500);

   -- Protected resource used to log
   protected Log_Manager is
      procedure Log_String(Msg: in Message_Notification);
   private
      Log : Unbounded_String;
   end Log_Manager;

   -- Dispatch current message.
   procedure Dispatch_Message(Msg:in Message);


end Notification;