import contextlib,io,unittest
from tools.qa.check_modular_actors import inspect

class ModularDeliveryTests(unittest.TestCase):
    def test_complete_authored_native_delivery(self):
        with contextlib.redirect_stdout(io.StringIO()):inspect()
