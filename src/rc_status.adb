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
with Control_Rods;    use Control_Rods;
with Coordinator;     use Coordinator;
with Nuclear_Physics; use Nuclear_Physics;
with Plant_Simulator; use Plant_Simulator;
with Notification;    use Notification;

-- This package implements tasks and resources for RC management. There are both
-- sporadic and periodic task that check and act over reactor circuit apparatus.
-- author: Alberto Franco
package body RC_Status is

   -- Implementation of periodic task for temperature checking. This task as
   -- other implemented here has been designed following the sporadic workload
   -- model.
   task body Water_Temperature_Status is
      Next_Activation:Time := Start_Time;
   begin
      loop
         delay until Next_Activation;
         Next_Activation := WATER_TEMPERATURE_STATUS_PERIOD + Clock;
         Check_Water_Pressure_And_Temp;
      end loop;
   end Water_Temperature_Status;

   -- Implementation of periodic RC pump status checking task. As other periodic
   -- tasks this implements Periodc_Task archetype.
   task body RC_Pump_Status is
      Next_Activation : Time := Start_Time;
   begin
      loop
         delay until Next_Activation;
         Next_Activation := RC_PUMP_STATUS_PERIOD + Clock;
         Check_RC_Pump_Operations;
      end loop;
   end RC_Pump_Status;

   -- Sporadic task for RC_Pressure actuation implementation
   task body RC_Pressure_Actuator is
      Next_Activation : Time := Start_Time;
      Pressure        : Float;
   begin
      loop
         delay until Next_Activation;
         RC_Pressure_Actuator_Control_Agent.Wait(Pressure => Pressure);

         Next_Activation := Clock + RC_PRESSURE_ACTUATOR_INTERARRIVAL;
         Change_RC_Pressure_To(Pressure);
      end loop;
   end RC_Pressure_Actuator;

   -- Control agent for RC_Pressure_Actutator implementation. This is a
   -- protected resource that manages the sporadic actuator for RC pressure
   protected body RC_Pressure_Actuator_Control_Agent is
      entry Wait(Pressure: out Float) when Activate is
      begin
         Pressure := Current_Pressure;
         Activate := False;
      end Wait;

      procedure Notify(New_Pressure: in Float) is
      begin
         Current_Pressure := New_Pressure;
         Activate := True;
      end Notify;
   end RC_Pressure_Actuator_Control_Agent;

   -----------------------------------------------------------------------------
   -- Job implementation
   -----------------------------------------------------------------------------

   -- Job for Water_Temperature_Status implementation. Checks the current boiling
   -- point of water and higher pressure when it is too near to the boiling
   -- point. Water has not to boil in RC.
   procedure Check_Water_Pressure_And_Temp is
      -- Current configuration for RC
      Current_Conf : constant RC_Configuration :=
                                   (Rods_Height       => Plant.Get_Rods_Height,
                                    RC_Water_Pressure => Plant.Get_RC_Pressure );
      -- Current boiling point of water inside RC
      Current_Boiling : constant Float := Get_Water_Boiling_Point(Plant.Get_RC_Pressure);
      -- Difference between boiling point and current
      Delta_Temp : constant Float := Current_Boiling - Get_RC_Temperature(Current_Conf);
   begin
      if Delta_Temp < WATER_BOIL_SAFE_LIMIT then
         if Plant.Get_RC_Pressure < PRESSURE_SAFE_LIMIT then
            RC_Pressure_Actuator_Control_Agent.Notify(Plant.Get_RC_Pressure + WATER_BOIL_PRESSURE_HIGH);
         else
            Control_Rods_Actuator_Control_Agent.Notify(WATER_BOIL_RODS_LOWER);
         end if;
      end if;
   end Check_Water_Pressure_And_Temp;

   -- Job implementation for RC_Pump_Status. Checks if the pump in rc is working
   -- and, if not, notifies it and switch to maintainance mode.
   procedure Check_RC_Pump_Operations is
      PUMP_OPERATIONAL_LIMIT : constant Float := 60.0;
      Notification           : constant Message_Notification :=
        (Switch => RC_PUMP, Params => Plant.RC_Pump_Flow);
   begin
      if Plant.RC_Pump_Flow < PUMP_OPERATIONAL_LIMIT and Mode_Changer.Get_Current_Mode /= MAINTAINANCE_MODE then
         Notification_Pipe_Control_Agent.Notify(Create_Status_Log(Notification));
         Notification_Pipe_Control_Agent.Notify(Create_Mode_Change(MAINTAINANCE_MODE));
      end if;
   end Check_RC_Pump_Operations;

   -- Job implementation for sporadic task RC_Pressure_Actuator, set the pressure
   -- to the given one. This changes reflect immediately.
   procedure Change_RC_Pressure_To(New_Pressure:Float) is
      Notification: constant Message_Notification := (RC_PRESSURE, New_Pressure);
   begin
      Notification_Pipe_Control_Agent.Notify(Create_Status_Log(Notification));
      Plant.Set_RC_Pressure(New_Pressure);
   end Change_RC_Pressure_To;

end RC_Status;
