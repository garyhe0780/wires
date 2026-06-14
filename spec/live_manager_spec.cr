require "./spec_helper"

describe CrystalLive::LiveManager do
  it "delivers patches to subscribed connections" do
    sent = [] of String
    connection = CrystalLive::Connection.new(->(message : String) { sent << message })
    CrystalLive::LiveManager.subscribe_connection("session-a", "widget", connection)

    CrystalLive::LiveManager.broadcast_patch("session-a", "widget", "<template for=\"widget\"></template>")

    sent.should eq(["<template for=\"widget\"></template>"])
  end

  it "does not deliver patches to unsubscribed connections" do
    sent = [] of String
    connection = CrystalLive::Connection.new(->(message : String) { sent << message })
    CrystalLive::LiveManager.subscribe_connection("session-a", "widget", connection)
    CrystalLive::LiveManager.unsubscribe_connection(connection)

    CrystalLive::LiveManager.broadcast_patch("session-a", "widget", "patch")

    sent.should be_empty
  end

  it "isolates subscriptions by component id" do
    widget_sent = [] of String
    clock_sent = [] of String
    widget = CrystalLive::Connection.new(->(message : String) { widget_sent << message })
    clock = CrystalLive::Connection.new(->(message : String) { clock_sent << message })

    CrystalLive::LiveManager.subscribe_connection("session-a", "widget", widget)
    CrystalLive::LiveManager.subscribe_connection("session-a", "clock", clock)

    CrystalLive::LiveManager.broadcast_patch("session-a", "widget", "widget-patch")

    widget_sent.should eq(["widget-patch"])
    clock_sent.should be_empty
  end

  it "isolates subscriptions by session id" do
    session_a_sent = [] of String
    session_b_sent = [] of String
    session_a = CrystalLive::Connection.new(->(message : String) { session_a_sent << message })
    session_b = CrystalLive::Connection.new(->(message : String) { session_b_sent << message })

    CrystalLive::LiveManager.subscribe_connection("session-a", "clock", session_a)
    CrystalLive::LiveManager.subscribe_connection("session-b", "clock", session_b)

    CrystalLive::LiveManager.broadcast_patch("session-a", "clock", "tick")

    session_a_sent.should eq(["tick"])
    session_b_sent.should be_empty
  end
end
