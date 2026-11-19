import ctypes
import ctypes.util
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


class ScreenshotBindingTest(unittest.TestCase):
    def test_command_survives_labwc_xml_conversion(self):
        # labwc converts attributes to nodes with xmlNodeSetContent.
        lib = ctypes.CDLL(ctypes.util.find_library('xml2'))
        lib.xmlNewNode.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        lib.xmlNewNode.restype = ctypes.c_void_p
        lib.xmlNodeSetContent.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        lib.xmlNodeGetContent.argtypes = [ctypes.c_void_p]
        lib.xmlNodeGetContent.restype = ctypes.c_void_p
        lib.xmlFreeNode.argtypes = [ctypes.c_void_p]
        free = ctypes.CFUNCTYPE(None, ctypes.c_void_p).in_dll(lib, 'xmlFree')
        config = ET.parse(Path(__file__).resolve().parents[1] / 'config/labwc/rc.xml')
        for key in ('Print', 'W-S-s'):
            command = config.find(f'.//keybind[@key="{key}"]/action').get('command').encode()
            node = lib.xmlNewNode(None, b'command')
            try:
                lib.xmlNodeSetContent(node, command)
                result = lib.xmlNodeGetContent(node)
                try:
                    self.assertEqual(ctypes.string_at(result), command)
                finally:
                    free(result)
            finally:
                lib.xmlFreeNode(node)
