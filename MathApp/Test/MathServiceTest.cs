using NUnit.Framework;
using openc_test_app.code;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace openc_test_app.test
{
    public class MathServiceTest
    {
        private MathService mathService = new MathService();

        [Test]
        public void add()
        {
            int a = 5;
            int b = 10;
            Assert.AreEqual(mathService.add(a, b), 15);
        }
    }
}
