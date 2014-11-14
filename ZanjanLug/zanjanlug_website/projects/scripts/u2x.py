#!/usr/bin/env python
#-*- coding:utf-8 -*-

import pygtk
pygtk.require('2.0')
import gtk
import HTMLParser


class Base:
	def delete_event(self, widget, event, data=None):
		return False

	def destroy(self, widget, data=None):
		gtk.main_quit()
	
    
	def convert_to_x(self,widget, data=None):
		textbuffer_input = self.textview_input.get_buffer()
		u = textbuffer_input.get_text(textbuffer_input.get_start_iter(),textbuffer_input.get_end_iter())
		
		textbuffer_output = self.textview_output.get_buffer()
		textbuffer_output.set_text(u.encode( 'ascii', 'xmlcharrefreplace'))
		
		cb = gtk.Clipboard()
		tb = textbuffer_output.get_text(textbuffer_output.get_start_iter(),textbuffer_output.get_end_iter())
		cb.set_text(tb)
	
	def convert_to_u(self,widget, data=None):
		textbuffer_input = self.textview_output.get_buffer()
		u = textbuffer_input.get_text(textbuffer_input.get_start_iter(),textbuffer_input.get_end_iter())
		
		textbuffer_output = self.textview_input.get_buffer()
		h= HTMLParser.HTMLParser()
		textbuffer_output.set_text(h.unescape(u))
		
		cb = gtk.Clipboard()
		tb = textbuffer_output.get_text(textbuffer_output.get_start_iter(),textbuffer_output.get_end_iter())
		cb.set_text(tb)

	def __init__(self):
		setting = gtk.settings_get_default()
		setting.set_long_property("gtk-button-images",True,"")
		self.window = gtk.Window(gtk.WINDOW_TOPLEVEL)
		self.window.maximize()
		self.window.connect("delete_event", self.delete_event)
		self.window.connect("destroy", self.destroy)
		
		hbox1 = gtk.HBox(homogeneous=False, spacing=0)
		
		self.textview_input = gtk.TextView()
		sw_input = gtk.ScrolledWindow()
		sw_input.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
		sw_input.set_shadow_type(gtk.SHADOW_ETCHED_IN)
		sw_input.add_with_viewport(self.textview_input)
		hbox1.pack_start(sw_input, expand=True, fill=True, padding=5)
		
		convert_to_x_button = gtk.Button("Convert to x")
		image = gtk.Image()
		image.set_from_stock("gtk-ok",gtk.ICON_SIZE_BUTTON)
		convert_to_x_button.set_image(image)
		convert_to_x_button.connect("clicked",self.convert_to_x)
		vbox_top = gtk.VBox(homogeneous=False, spacing=0)
		vbox_top.pack_start(convert_to_x_button, expand=False, fill=False, padding=5)
		
		hbox1.pack_start(vbox_top, expand=False, fill=False, padding=5)
		
		
		hbox2 = gtk.HBox(homogeneous=False, spacing=0)
		
		self.textview_output = gtk.TextView()
		sw_output = gtk.ScrolledWindow()
		sw_output.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
		sw_output.set_shadow_type(gtk.SHADOW_ETCHED_IN)
		sw_output.add_with_viewport(self.textview_output)
		hbox2.pack_start(sw_output, expand=True, fill=True, padding=5)
		
		convert_to_u_button = gtk.Button("Convert to u")
		image = gtk.Image()
		image.set_from_stock("gtk-ok",gtk.ICON_SIZE_BUTTON)
		convert_to_u_button.set_image(image)
		convert_to_u_button.connect("clicked",self.convert_to_u)
		vbox_bottom = gtk.VBox(homogeneous=False, spacing=0)
		vbox_bottom.pack_start(convert_to_u_button, expand=False, fill=False, padding=5)
		
		hbox2.pack_start(vbox_bottom, expand=False, fill=False, padding=5)
		
		vbox = gtk.VBox(homogeneous=False, spacing=0)
		vbox.pack_start(hbox1, expand=True, fill=True, padding=5)
		vbox.pack_start(hbox2, expand=True, fill=True, padding=5)
		
		self.window.add(vbox)
		self.window.show_all()

	def main(self):
		gtk.main()

#print __name__
if __name__ == "__main__":
    base = Base()
    base.main()



