package main

import (
	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"github.com/go-gl/glfw/v3.3/glfw"
)

var options = []flutter.Option{
	// flutter.WindowInitialDimensions(1280, 720),
	flutter.AddPlugin(&WindowMaximization{}),
}

// WindowMaximization .
type WindowMaximization struct{}

var _ flutter.Plugin = &WindowMaximization{}     // compile-time type check
var _ flutter.PluginGLFW = &WindowMaximization{} // compile-time type check
// WindowNotResizable struct must implement InitPlugin and InitPluginGLFW

// InitPlugin .
func (p *WindowMaximization) InitPlugin(messenger plugin.BinaryMessenger) error {
	// nothing to do
	return nil
}

// InitPluginGLFW .
func (p *WindowMaximization) InitPluginGLFW(window *glfw.Window) error {
	window.Maximize()
	return nil
}