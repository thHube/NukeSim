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
with Coordinator;     use Coordinator;
with Notification;    use Notification;
with Control_Rods;    use Control_Rods;
with Nuclear_Physics; use Nuclear_Physics;
with Plant_Simulator; use Plant_Simulator;
with Ada.Text_IO;     use Ada.Text_IO;

-- Status checking for turbine circuit implementation
-- author: Alberto Franco
package body TC_Status is

   -- Periodic task implementation. This task is abortable during mode change
   task body Heat_Exchange_Temp_Status is
      Next_Activation: Time := Start_Time;
   begin
      Start_Deamon.Wait_For_System_Start;
      select
         Mode_Changer.Goto_Maintainance_Mode;
         Put_Line("[MODE CHANGER]: Abort Heat_Exchange_Temp_Status");
         Mode_Changer.Restart_Operations;
      then abort
         loop
            delay until Next_Activation;
            Next_Activation := Clock + HEAT_EXCHANGE_TEMP_STATUS_PERIOD;

            Check_Heat_Exchange_Temperature;
         end loop;
      end select;
   end Heat_Exchange_Temp_Status;

   -- Implementation of TC_Pump_Status
   task body TC_Pump_Status is
      Next_Activation: Time := Start_Time;
   begin
      Start_Deamon.Wait_For_System_Start;
      select
         Mode_Changer.Goto_Maintainance_Mode;
         Put_Line("[MODE CHANGER]: Abort TC_Pump_Status");
         Mode_Changer.Restart_Operations;
      then abort
         loop
            delay until Next_Activation;
            Next_Activation := Clock + TC_PUMP_STATUS_PERIOD;
            Check_TC_Pump_Operation;
         end loop;
      end select;
   end TC_Pump_Status;

   -- Periodic task Cooling_System_Status implementation.
   task body Cooling_System_Status is
      Next_Activation: Time := Start_Time;
   begin
      Start_Deamon.Wait_For_System_Start;
      select
         Mode_Changer.Goto_Maintainance_Mode;
         Put_Line("[MODE CHANGER]: Abort Cooling_System_Status");
         Mode_Changer.Restart_Operations;
      then abort
         loop
            delay until Next_Activation;
            Next_Activation := Clock + COOLING_SYSTEM_STATUS_PERIOD;
            Check_Cooling_System;
         end loop;
      end select;
   end Cooling_System_Status;

   -----------------------------------------------------------------------------
   -- Job implementation
   -----------------------------------------------------------------------------

   -- Job implementation for Heat_Exchange_Temp_Status. Checks for heat
   -- exchanged at connection between the two circuits and, if less than its
   -- soft limit, higher control rods of a given offset to increase temp
   procedure Check_Heat_Exchange_Temperature is
      HEAT_SOFT_LIMIT : constant Float := 50.0;
      RODS_SOFT_OFFSET: constant Float := 100.0;
      Current_Conf    : constant TC_Configuration := Plant.Get_TC_Configuration;
   begin
      if Get_TC_Temperature(Current_Conf) <= HEAT_SOFT_LIMIT then
         Control_Rods_Actuator_Control_Agent.Notify(Rods_Offset => RODS_SOFT_OFFSET);
      end if;
   end Check_Heat_Exchange_Temperature;

   -- Job implementation for TC_Pump_Status. Checks for the correct operation
   -- of the turbine circuit pump. If it is not working right it notifies it
   -- and changes the operation mode.
   procedure Check_TC_Pump_Operation is
      TC_PUMP_OPERATIONAL_LIMIT : constant Float := 60.0;
      Notification              : constant Message_Notification :=
        (Switch => TC_PUMP, Params => Plant.TC_Pump_Flow);
   begin
      if Plant.TC_Pump_Flow < TC_PUMP_OPERATIONAL_LIMIT then
         Notification_Pipe_Control_Agent.Notify(Create_Status_Log(Notification));
         Notification_Pipe_Control_Agent.Notify(Create_Mode_Change(MAINTAINANCE_MODE));
      end if;
   end Check_TC_Pump_Operation;

   -- Job implementation for Cooling_System_Status. Checks for temperature
   -- after the cooling if it is higher than the limit the system is moved to
   -- maintainance mode.
   procedure Check_Cooling_System is
      COOLING_SYSTEM_TEMP_LIMIT : constant Float := 75.0;
      Notification              : constant Message_Notification :=
         (Switch => COOLING_SYSTEM, Params => Plant.Cooling_System_Temp);
   begin
      if Plant.Cooling_System_Temp > COOLING_SYSTEM_TEMP_LIMIT then
         Notification_Pipe_Control_Agent.Notify(Create_Status_Log(Notification));
         Notification_Pipe_Control_Agent.Notify(Create_Mode_Change(MAINTAINANCE_MODE));
      end if;
   end Check_Cooling_System;

end TC_Status;
