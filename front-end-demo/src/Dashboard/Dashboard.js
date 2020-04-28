import React from 'react';
import {Button, Select} from 'antd';
import 'antd/dist/antd.css';
import './Dashboard.css';
import { ToolOutlined} from '@ant-design/icons'

const Option = Select.Option;

const children = [];

children.push(<Option key="1">COMPILER:GCC8.0</Option>);
children.push(<Option key="2">COMPILER:GCC7.0</Option>);
children.push(<Option key="3">COMPILER:GCC6.0</Option>);
children.push(<Option key="4">COMPILER:GCC5.0</Option>);
children.push(<Option key="5">RUNTIME:LLVM</Option>);
children.push(<Option key="6">RUNTIME:GOMP</Option>);
children.push(<Option key="7">LIB:MPI</Option>);
children.push(<Option key="8">LIB:MKL</Option>);

class Dashboard extends React.Component {
    state = {};
    
    componentDidMount() {
        
    };
              
    render() {
        return (
            <div>
                <div className = "logo">
                    <b><ToolOutlined /> | onlineCompiler</b>
                </div>
                <div className = "divider">
                
                </div>
                <div className = "opts">
                    <Button>Home</Button>
                    <Button>Upload</Button>
                    <Button>Save</Button>
                    <Button type="primary">Compile</Button>
                    <Select
                      mode="multiple"
                      style={{ width: '77%' }}
                      placeholder="Please select compile configurations"
                      defaultValue={['COMPILER:GCC8.0', 'RUNTIME:LLVM']}
                    >
                      {children}
                    </Select>
                </div>
                <div className = "texts">
                    <textarea className = "textbox" placeholder="Type or upload your code"/>
                    <textarea className = "textbox" placeholder="Results/Error messages will be shown here"/>
                </div>
            </div>
        )
    };
}

export default Dashboard;
