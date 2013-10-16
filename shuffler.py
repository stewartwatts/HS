import unittest
import numpy as np
from sklearn.datasets import make_classification

class TestShuffler(unittest.TestCase):
    def setUp(self):
        np.random.seed(seed=1)
        # dataset: tuple of (data -> num_ex x num_feat, target -> num_ex x 1)
        self.DS = make_classification(n_informative=4,
                                      n_classes=5)
                
    def test_mc_bc(self):
        # [ < ex > ] --> [ <[ex0]> ... <ex11> ]
        # multiclass target c [0,12) --> [0, 0, 1 ... 0, 0, 0]
        pass
        
    def tearDown(self):
        pass

# Transofrming functions from multiclass to binaryclass

def target_mc_bc(cls, n_cls):
    """cls from 0. to n_cls-1."""
    assert int(cls) in range(n_cls)
    out = np.zeros(n_cls)
    out[cls] = 1.
    return out

def data_mc_bc(vec, n_cls):
    assert len(vec) % n_cls == 0, "\nlen(data vector) MOD num classes != 0\n"
    lencap = len(vec) / n_cls
    caps = {i: vec[(i*lencap):((i+1)*lencap)] for i in range(n_cls)}
    print caps
    out = np.zeros(n_cls*len(vec)).reshape(n_cls, len(vec))
    for i in xrange(n_cls):
        # set the current capsule
        out[i,:lencap] = caps[i]
        # set the randomly shuffled other capsules
        ind = range(n_cls)
        ind = [x for x in ind if x != i]
        np.random.shuffle(ind)
        for j in range(1,n_cls):
            out[i,(j*lencap):((j+1)*lencap)] = caps[ind[j-1]]
    return out

def dataset_mc_bc(ds, n_cls):
    """
    ds: tuple with (data as NxF numpy array, target as len(N) numpy vector)
    """
    n_ex = len(ds[1])      # length of the target vector
    n_ft = len(ds[0][0])   # length of first data vector
    lencap = n_ft / n_cls  # number of feats / classes -> length of each capsule
    X = np.zeros(n_ex * n_cls * n_ft).reshape(n_ex * n_cls, n_ft)  # data matrix will be expanded by factor of n_cls
    y = np.zeros(n_ex * n_cls)                                     # as will targets
    for i in range(n_ex):
        X[(i*n_cls):((i+1)*n_cls),:] = data_mc_bc(ds[0][i])
        y[(i*n_cls):((i+1)*n_cls)] = target_mc_bc(ds[1][i])
    return (X,y)
    
if __name__ == "__main__":
    unittest.main()
